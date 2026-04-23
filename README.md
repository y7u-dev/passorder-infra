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

| 문제 | 원인 | 해결 | 개선 / 배운 점 |
|---|---|---|---|
| EKS 노드 그룹 생성 실패 (Spot) | 신규 AWS 계정은 Spot Instance vCPU quota가 기본 0으로 설정됨 | `aws ec2 describe-instance-types --filters "Name=free-tier-eligible,Values=true"`로 사용 가능한 타입 확인 후 On-Demand로 변경 | Spot은 비용 절감 효과가 크지만 신규 계정 quota 제한과 회수 리스크가 있음. 실제 운영에서는 On-Demand 최소 1개 + Spot 혼합 전략이 적합함을 인지 |
| Too many pods | t3.small은 ENI 기반으로 노드당 최대 Pod 수가 11개로 제한됨 | 노드 수를 3개로 증설하여 해결 | 인스턴스 타입 선택 시 Pod 밀도(ENI 한도)를 사전에 고려해야 함. 장기적으로 HPA + Cluster Autoscaler 도입으로 노드 수를 동적으로 관리하는 구조가 필요 |
| .terraform/ Git 추적 | .gitignore 생성 전에 `git add .`를 실행해서 685MB 프로바이더 바이너리가 추적됨 | `git rm -r --cached` 로 추적 해제 후 `git reset --soft`로 커밋 되돌려 재커밋 | Git은 이미 추적 중인 파일을 .gitignore로 제외하지 못함. 앞으로는 새 폴더/도구 추가 전 .gitignore를 먼저 작성하는 습관이 중요 |
| git push 실패 (detached HEAD) | Jenkins `checkout scm`은 브랜치가 아닌 특정 커밋 SHA를 직접 체크아웃하기 때문에 HEAD가 브랜치를 가리키지 않음 | `git checkout -B main origin/main`으로 origin/main 기준으로 브랜치를 강제 생성 후 push | Jenkins의 Git checkout 동작 방식을 이해하게 됨. `checkout scm` vs 직접 checkout의 차이를 인지하고, CI 환경에서는 항상 명시적으로 브랜치를 설정해야 함 |
| Docker npm permission denied | `USER node` 선언 이후 명령어가 node 유저 권한으로 실행되는데, `WORKDIR /app`이 root 소유라 node 유저가 파일을 쓸 수 없음 | `USER node`를 Dockerfile 마지막으로 이동해서 빌드는 root로, 실행만 node 유저로 분리 | Linux 권한 구조와 Docker 레이어 실행 순서를 이해하게 됨. 보안을 위해 컨테이너 실행 유저를 낮추되, 빌드 단계에서의 권한 분리를 명확히 설계해야 함 |
| Helm values.yaml 변경 미반영 | `deployment.yaml`에 이미지가 하드코딩되어 있어 values.yaml 변경이 무시됨. `helm template` 명령으로 렌더링 결과를 확인해서 원인 파악 | `image: {{ .Values.image.repository }}:{{ .Values.image.tag }}`로 템플릿 변수로 교체 | Helm은 values.yaml을 자동으로 주입하지 않음. 템플릿에 명시적으로 변수를 참조해야 하며, `helm template` 명령으로 렌더링 결과를 사전에 검증하는 습관이 중요 |

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

이 프로젝트 이전에 온프레미스 환경(VMware + GNS3)에서 동일한 아키텍처를 직접 구성했습니다.
직접 구성해본 경험 덕분에 AWS 관리형 서비스가 어떤 복잡성을 추상화하는지 이해할 수 있었습니다.

| 항목 | 온프레미스 | AWS |
|---|---|---|
| 로드밸런서 | MetalLB 직접 설치 | ALB (관리형) |
| 네트워크 | Calico BGP 직접 설정 | VPC CNI |
| 게이트웨이 이중화 | HSRP 직접 구성 | Multi-AZ |
| 접근 제어 | Bastion Host + ACL + iptables | Security Group + IAM |
| TLS | cert-manager self-signed | ACM |
| 프로비저닝 | 수동 VM 설정 | Terraform |

## 개선 방향

### Scheduled Scaling 도입
패스오더는 출근 시간대인 **오전 8~9시에 전체 트래픽의 약 33%가 집중**되는 특성이 있습니다.
현재 HPA는 CPU 사용률이 올라간 뒤 Pod를 확장하는 **반응형** 방식이라
트래픽 급증 초반에 응답 지연이 발생할 수 있습니다.

KEDA의 CronScaler를 활용하면 트래픽 증가 전에 미리 Pod를 확장하는
**예측형 스케일링**이 가능합니다.

```yaml
# 오전 8시 트래픽 급증 전 미리 스케일 아웃
triggers:
  - type: cron
    metadata:
      timezone: Asia/Seoul
      start: "50 7 * * 1-5"   # 평일 7:50 스케일 아웃 (8시 전 준비)
      end: "10 9 * * 1-5"     # 평일 9:10 스케일 인
      desiredReplicas: "5"
```

HPA와 KEDA를 함께 사용하면 예측 가능한 트래픽은 KEDA가,
예상치 못한 트래픽 급증은 HPA가 대응하는 이중 전략이 가능합니다.
