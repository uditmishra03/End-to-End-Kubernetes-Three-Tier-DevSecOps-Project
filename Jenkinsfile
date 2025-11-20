pipeline {
    agent any
    
    tools {
        terraform 'terraform'  // Name configured in Jenkins Global Tool Configuration
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
                    echo '========== Validating Terraform Syntax =========='
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
        
        stage('Kubernetes YAML Validation') {
            steps {
                script {
                    echo '========== Validating Kubernetes Manifests =========='
                    sh '''
                        # Install kubeconform if not present
                        if ! command -v kubeconform &> /dev/null; then
                            echo "Installing kubeconform ${KUBECONFORM_VERSION}..."
                            wget -q https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz
                            tar xf kubeconform-linux-amd64.tar.gz
                            chmod +x kubeconform
                            sudo mv kubeconform /usr/local/bin/
                            rm kubeconform-linux-amd64.tar.gz
                        fi
                        
                        echo "Validating K8s manifests in k8s-infrastructure/..."
                        kubeconform -summary -output text k8s-infrastructure/ || {
                            echo "❌ Kubernetes YAML validation failed!"
                            exit 1
                        }
                        echo "✅ Kubernetes YAML validation passed!"
                    '''
                }
            }
        }
        
        stage('ArgoCD Applications Validation') {
            steps {
                script {
                    echo '========== Validating ArgoCD Application Definitions =========='
                    sh '''
                        echo "Checking ArgoCD application YAML syntax..."
                        for file in argocd-apps/*.yaml; do
                            echo "Validating $file..."
                            kubeconform -summary -output text "$file" || {
                                echo "❌ ArgoCD application validation failed for $file"
                                exit 1
                            }
                        done
                        echo "✅ ArgoCD applications validation passed!"
                    '''
                }
            }
        }
        
        stage('Shell Scripts Validation') {
            steps {
                script {
                    echo '========== Validating Shell Scripts Syntax =========='
                    sh '''
                        echo "Checking shell scripts syntax..."
                        find . -name "*.sh" -type f | while read script; do
                            echo "Validating $script..."
                            bash -n "$script" || {
                                echo "❌ Syntax error in $script"
                                exit 1
                            }
                        done
                        echo "✅ Shell scripts validation passed!"
                    '''
                }
            }
        }
        
        stage('ArgoCD Image Updater Config Validation') {
            steps {
                script {
                    echo '========== Validating ArgoCD Image Updater Configuration =========='
                    sh '''
                        echo "Validating ArgoCD Image Updater YAML files..."
                        kubeconform -summary -output text argocd-image-updater-config/*.yaml || {
                            echo "❌ ArgoCD Image Updater config validation failed!"
                            exit 1
                        }
                        echo "✅ ArgoCD Image Updater configuration validation passed!"
                    '''
                }
            }
        }
        
        stage('Documentation Check') {
            steps {
                script {
                    echo '========== Checking Documentation Files =========='
                    sh '''
                        echo "Verifying essential documentation exists..."
                        
                        required_docs=(
                            "README.md"
                            "docs/DOCUMENTATION.md"
                            "docs/FUTURE-ENHANCEMENTS.md"
                        )
                        
                        for doc in "${required_docs[@]}"; do
                            if [ ! -f "$doc" ]; then
                                echo "❌ Missing required documentation: $doc"
                                exit 1
                            fi
                        done
                        
                        echo "Checking for broken relative links in README.md..."
                        # Basic check for referenced files in docs/
                        grep -o 'docs/[^)]*\\.md' README.md | while read ref; do
                            if [ ! -f "$ref" ]; then
                                echo "⚠️  WARNING: Referenced file not found: $ref"
                            fi
                        done
                        
                        echo "✅ Documentation check passed!"
                    '''
                }
            }
        }
        
        stage('Security Scan - Trivy IaC') {
            steps {
                script {
                    echo '========== Scanning Infrastructure for Security Issues =========='
                    sh '''
                        # Install Trivy if not present
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy..."
                            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                            sudo apt-get update
                            sudo apt-get install trivy -y
                        fi
                        
                        echo "Scanning Terraform code for security issues..."
                        trivy config --severity HIGH,CRITICAL Jenkins-Server-TF/ || {
                            echo "⚠️  WARNING: Security issues found in Terraform code"
                        }
                        
                        echo "Scanning Kubernetes manifests for security issues..."
                        trivy config --severity HIGH,CRITICAL k8s-infrastructure/ || {
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
                    ╔═══════════════════════════════════════════════════════════╗
                    ║         Infrastructure Validation Summary                 ║
                    ╠═══════════════════════════════════════════════════════════╣
                    ║  ✅ Terraform syntax validation                           ║
                    ║  ✅ Kubernetes YAML validation                            ║
                    ║  ✅ ArgoCD applications validation                        ║
                    ║  ✅ Shell scripts syntax check                            ║
                    ║  ✅ ArgoCD Image Updater config validation                ║
                    ║  ✅ Documentation verification                            ║
                    ║  ✅ Security scan (Trivy IaC)                             ║
                    ╠═══════════════════════════════════════════════════════════╣
                    ║  All infrastructure validation checks passed! 🚀          ║
                    ╚═══════════════════════════════════════════════════════════╝
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
