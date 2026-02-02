# Setup Store

A collection of useful setup configurations, scripts, and templates for various services and platforms. This repository serves as a centralized store for infrastructure as code, deployment configurations, and service setups.

## 📁 Repository Structure

This repository is organized by service/platform:

- **[mlflow/](./mlflow)** - MLflow platform setup for ML lifecycle management
- **[gcp/](./gcp)** - Google Cloud Platform configurations
- **[aws/](./aws)** - Amazon Web Services configurations
- **[azure/](./azure)** - Microsoft Azure configurations
- **[docker/](./docker)** - Docker and Docker Compose setups
- **[kubernetes/](./kubernetes)** - Kubernetes manifests and Helm charts
- **[terraform/](./terraform)** - Terraform infrastructure as code
- **[ansible/](./ansible)** - Ansible playbooks and roles

Each directory contains its own README with specific documentation and examples.

## 🚀 Getting Started

1. Browse the directory for the service you're interested in
2. Read the service-specific README for prerequisites and instructions
3. Copy or adapt the configurations for your needs
4. Follow the setup instructions in each directory

## 📝 Usage

Each service directory contains:
- Configuration files (YAML, JSON, HCL, etc.)
- Setup scripts
- Documentation
- Examples and best practices

## 🤝 Contributing

Contributions are welcome! To add a new setup:

1. Create a new directory for your service/platform
2. Add a README.md explaining the setup
3. Include configuration files and examples
4. Document prerequisites and usage
5. Submit a pull request

### Guidelines

- Keep configurations generic and reusable
- Document all prerequisites
- Include example usage
- Remove sensitive information (credentials, API keys, etc.)
- Follow existing directory structure patterns

## ⚠️ Security

**Important:** Never commit sensitive information such as:
- API keys
- Passwords
- Private keys
- Service account credentials
- Access tokens

Use environment variables, secret managers, or configuration templates instead.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Useful Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [GCP Documentation](https://cloud.google.com/docs)
- [Azure Documentation](https://docs.microsoft.com/azure/)
