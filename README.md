# CyberS_Devops_Task
Github Repo for the DevOps Task ( CyberSapient-Dubai)

--------------------------------------------------------------------------------------------------------------------------------
�
�
 DevOps Engineer Task – CI/CD and Infra Setup 
�
�
 Objective: 
Deploy one of the provided applications (backend/frontend/fullstack) with scalable, 
production-grade DevOps practices. 
�
�
 Scope of Work: 
● Containerize services using Docker 
● Setup CI/CD pipeline (GitHub Actions or GitLab CI) 
● Infrastructure provisioning using Terraform or Pulumi 
● K8s manifests / Helm Charts or Docker Compose (for orchestration) 
● Basic monitoring (Prometheus + Grafana or similar) 
�
�
 Tech Recommendations: 
● GitHub Actions / GitLab 
● Docker, Kubernetes 
● Terraform / Pulumi 
● AWS / GCP / any cloud platform 
● Monitoring stack (ELK / Grafana / Prometheus) 
�
�
 Deliverables: 
● GitHub repo with infra files 
● Architecture/infra diagram 
● short Loom walkthrough on the entire setup 
⏱ Recommended Timeline: 5 to 6 days 
✅
 Bonus Ideas: 
● Set up staging + production environments 
● Auto-deploy on merge to main 
● Secrets management via Vault or SSM 
--------------------------------------------------------------------------------------------------------------------------------

NOTES:
1) use multi stage in prod env , and not in stag env
2) private subnet and nat gateway for prod