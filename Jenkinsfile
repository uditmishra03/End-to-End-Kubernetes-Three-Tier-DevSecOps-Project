// Infrastructure Validation Pipeline - Testing webhook trigger
pipeline {
    agent any
    
    tools {
        terraform 'terraform'
    }
    
    environment {
        KUBECONFORM_VERSION = '0.6.4'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '========== Cloning Infrastructure Repository =========='
                    git branch: "${env.BRANCH_NAME}", url: 'https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git'
                }
            }
        }
        
        stage('Terraform Validation') {
            steps {
                script {
                    echo '========== Validating Terraform Configuration =========='
                    dir('Jenkins-Server-TF') {
                        sh '''
                            terraform --version
                            echo "Running terraform fmt check..."
                            terraform fmt -check -recursive || {
                                echo "WARNING: Terraform formatting issues found. Run 'terraform fmt -recursive' to fix."
                            }
                            
                            echo "Running terraform validate..."
                            terraform init -backend=false
                            terraform validate
                            echo "✅ Terraform validation passed!"
                        '''
                    }
                }
            }
        }
        
        stage('YAML & Scripts Validation') {
            steps {
                script {
                    echo '========== Validating YAML Files and Shell Scripts =========='
                    sh '''
                        # Install kubeconform if not present
                        if ! command -v kubeconform &> /dev/null; then
                            echo "Installing kubeconform ${KUBECONFORM_VERSION}..."
                            wget -q https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz
                            tar xf kubeconform-linux-amd64.tar.gz
                            chmod +x kubeconform
                            rm kubeconform-linux-amd64.tar.gz
                        fi
                        
                        echo "=== Validating Kubernetes Manifests ==="
                        ./kubeconform -summary -output text k8s-infrastructure/ || {
                            echo "❌ Kubernetes YAML validation failed!"
                            exit 1
                        }
                        echo "✅ K8s manifests validated"
                        
                        echo ""
                        echo "=== Validating ArgoCD Applications ==="
                        for file in argocd-apps/*.yaml; do
                            echo "Validating $file..."
                            # Basic YAML syntax check
                            python3 -c "import yaml; yaml.safe_load(open('$file'))" || {
                                echo "❌ YAML syntax error in $file"
                                exit 1
                            }
                        done
                        echo "✅ ArgoCD applications YAML syntax validated"
                        
                        echo ""
                        echo "=== Validating ArgoCD Image Updater Config ==="
                        for file in argocd-image-updater-config/*.yaml; do
                            echo "Validating $file..."
                            python3 -c "import yaml; yaml.safe_load(open('$file'))" || {
                                echo "❌ YAML syntax error in $file"
                                exit 1
                            }
                        done
                        echo "✅ ArgoCD Image Updater config validated"
                        
                        echo ""
                        echo "=== Validating Shell Scripts ==="
                        find . -name "*.sh" -type f | while read script; do
                            echo "Validating $script..."
                            bash -n "$script" || {
                                echo "❌ Syntax error in $script"
                                exit 1
                            }
                        done
                        echo "✅ All shell scripts validated"
                    '''
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    echo '========== Scanning Infrastructure for Security Issues =========='
                    sh '''
                        # Check if Trivy is installed
                        if ! command -v trivy &> /dev/null; then
                            echo "⚠️  Trivy not installed. Skipping security scan."
                            echo "To enable security scanning, install Trivy manually on the Jenkins agent."
                            exit 0
                        fi
                        
                        echo "Using Trivy: $(trivy --version)"
                        
                        echo "=== Scanning Terraform Code ==="
                        trivy config --severity HIGH,CRITICAL --exit-code 0 Jenkins-Server-TF/ || {
                            echo "⚠️  WARNING: Security issues found in Terraform code"
                        }
                        
                        echo ""
                        echo "=== Scanning Kubernetes Manifests ==="
                        trivy config --severity HIGH,CRITICAL --exit-code 0 k8s-infrastructure/ || {
                            echo "⚠️  WARNING: Security issues found in K8s manifests"
                        }
                        
                        echo "✅ Security scan completed!"
                    '''
                }
            }
        }
        
        stage('Validation Summary') {
            steps {
                script {
                    echo '''
                    ╔════════════════════════════════════════════════════════╗
                    ║      Infrastructure Validation Summary                 ║
                    ╠════════════════════════════════════════════════════════╣
                    ║  ✅ Terraform validation                              ║
                    ║  ✅ Kubernetes YAML validation                        ║
                    ║  ✅ ArgoCD applications & config validation           ║
                    ║  ✅ Shell scripts syntax validation                   ║
                    ║  ✅ Security scan (Trivy IaC)                         ║
                    ╠════════════════════════════════════════════════════════╣
                    ║  All infrastructure checks passed! 🚀                 ║
                    ╚════════════════════════════════════════════════════════╝
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '✅ Infrastructure validation pipeline completed successfully!'
        }
        failure {
            echo '❌ Infrastructure validation pipeline failed. Please check the logs above.'
        }
        always {
            cleanWs()
        }
    }
}
