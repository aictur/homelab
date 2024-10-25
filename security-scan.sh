#!bash
PROJECT_PATH=$(realpath $(dirname "$0"))
docker run --rm -v $PROJECT_PATH:/path zricethezav/gitleaks:latest git /path
docker run --rm -v $PROJECT_PATH:/myapp -w /myapp aquasec/trivy config --ignorefile ./.trivyignore.yaml .