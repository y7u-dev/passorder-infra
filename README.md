# passorder-infra

패스오더(passorder.co.kr) 카페 주문 플랫폼을 모방한 MSA 인프라 구성 프로젝트.  
페이타랩 DevOps Engineer 포트폴리오 목적으로 실제 기술 스택을 직접 구현했습니다.

---

## 아키텍처

```
개발자(로컬)
    │ git push
    ▼
GitHub (passorder-infra)
    │ Webhook
    ▼
Jenkins (EC2 t3.small)        ← CI
    │ docker build + push
    ▼
ECR (이미지 저장소)
    │ values.yaml 태그 업데이트
    ▼
Argo CD (EKS 내부)            ← CD (GitOps)
    │ Helm Chart sync
    ▼
EKS Cluster (Spot Instance)   ← 실행 환경
    ├── passorder-api Pod
    ├── Prometheus + Grafana   ← 메트릭 모니터링
    └── Datadog Agent          ← APM + 인프라 모니터링
```

---

## 기술 스택

| 분류 | 기술 |
|---|---|
| 언어 | Node.js (Express) |
| 컨테이너 | Docker |
| 클러스터 | AWS EKS (t3.small, On-Demand) |
| 이미지 저장소 | AWS ECR |
| IaC | Terraform |
| CI | Jenkins (EC2) |
| CD | Argo CD (GitOps) |
| 패키지 관리 | Helm |
| 메트릭 모니터링 | Prometheus + Grafana |
| APM | Datadog |
| 오토스케일링 | Kubernetes HPA |

---

## 주요 설계 결정

### Jenkins를 관리형 CI 대신 선택한 이유
배포 빈도가 높을수록 GitHub Actions 같은 관리형 CI는 비용이 선형으로 증가하지만,  
Jenkins는 EC2 고정 비용만 발생합니다. 페이타랩이 Jenkins를 선택한 것도 같은 맥락으로 판단했습니다.

### Spot Instance + On-Demand 혼합 전략
순수 Spot Instance는 AWS가 회수 시 서비스 중단 리스크가 있습니다.  
실제 운영에서는 On-Demand 최소 1개 + Spot 혼합 구성을 권장합니다.  
(신규 계정 Spot quota 제한으로 현재 On-Demand로 구성)

### 노드를 프라이빗 서브넷에 배치
외부에서 노드 직접 접근을 차단하고, 외부 통신은 NAT Gateway를 통해서만 허용합니다.

### ECR 이미지 스캔 활성화
이미지 push마다 CVE 취약점을 자동 스캔해서 취약한 이미지가 운영 환경에 배포되는 걸 방지합니다.

### GitOps 패턴 (Jenkins + Argo CD 역할 분리)
- Jenkins: 코드 → Docker 이미지 빌드 + ECR push (CI)
- Argo CD: Git 상태를 클러스터에 반영 (CD)
- 배포 이력이 Git 커밋으로 남아 롤백이 용이합니다.

---

## CI/CD 흐름

```
1. git push → GitHub Webhook → Jenkins 자동 트리거
2. Jenkins: docker build → ECR push → values.yaml 이미지 태그 업데이트
3. Argo CD: values.yaml 변경 감지 → Helm Chart 렌더링 → EKS 배포
```

---

## 보안 설계

| 레이어 | 적용 내용 |
|---|---|
| 컨테이너 | node 유저 실행 (root 권한 제거), alpine 경량 이미지 |
| 네트워크 | EKS 노드 프라이빗 서브넷 배치, Security Group 최소 포트 개방 |
| IAM | 클러스터/노드별 최소 권한 Role 분리 |
| 이미지 | ECR scan_on_push 활성화 |
| 수명주기 | ECR lifecycle policy로 최근 10개 이미지만 유지 |

---

## 비용 최적화

| 항목 | 전략 |
|---|---|
| NAT Gateway | single_nat_gateway = true (1개로 절감) |
| EKS 노드 | t3.small, min_size = 0 (미사용 시 0개로 축소) |
| ECR | lifecycle policy로 스토리지 비용 절감 |

---

## 트러블슈팅

| 문제 | 원인 | 해결 |
|---|---|---|
| EKS 노드 그룹 생성 실패 | 신규 계정 Spot Instance quota 0 | On-Demand로 변경 |
| t3.medium 인스턴스 실패 | Free Tier 미지원 | `describe-instance-types`로 적격 타입 확인 후 t3.small 선택 |
| Too many pods | t3.small 노드당 Pod 최대 11개 한도 | 노드 수 증설 |
| .terraform/ Git 추적 | .gitignore 생성 전 git add | git reset --soft 후 재커밋 |
| Jenkinsfile 빈 파일 | 파일 truncate 상태로 push | 전체 재작성 후 push |
| git push 실패 (detached HEAD) | Jenkins checkout이 특정 커밋을 직접 체크아웃 | git checkout -B main origin/main 사용 |
| Datadog API Key 오류 | Application Key를 API Key로 혼동 | Datadog 콘솔에서 올바른 API Key 발급 |

---

## API 명세

| Method | Path | 설명 |
|---|---|---|
| GET | /health | 서비스 상태 확인 |
| GET | /api/menus | 전체 메뉴 조회 |
| GET | /api/menus/:id | 특정 메뉴 상세 |
| POST | /api/orders | 주문 생성 |
| GET | /api/orders/:id | 주문 상태 조회 |

---

## 온프레미스 vs AWS 비교

이 프로젝트 이전에 온프레미스 환경에서 동일한 아키텍처를 직접 구성했습니다.

| 항목 | 온프레미스 | AWS |
|---|---|---|
| 로드밸런서 | MetalLB 직접 설치 | ALB (관리형) |
| 네트워크 | Calico BGP 직접 설정 | VPC CNI |
| 게이트웨이 이중화 | HSRP 직접 구성 | Multi-AZ |
| 접근 제어 | Bastion Host + ACL + iptables | Security Group + IAM |
| TLS | cert-manager self-signed | ACM |
| 프로비저닝 | 수동 VM 설정 | Terraform |