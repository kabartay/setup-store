# Contributing to Setup Store

Thank you for considering contributing to Setup Store! This document provides guidelines for contributing new service setups and improvements.

## How to Contribute

### Adding a New Service Setup

1. **Create a Directory**
   - Create a new directory with a clear, descriptive name (lowercase, use hyphens for spaces)
   - Example: `my-service` or `service-name`

2. **Add a README**
   - Create a `README.md` in your directory
   - Include the following sections:
     - Title and brief description
     - Contents (what's included)
     - Quick Start guide
     - Prerequisites
     - Documentation links

3. **Add Configuration Files**
   - Include all necessary configuration files
   - Use clear, descriptive filenames
   - Add comments explaining configuration options
   - Provide example values where appropriate

4. **Documentation**
   - Explain each configuration file's purpose
   - Document all prerequisites and dependencies
   - Include step-by-step setup instructions
   - Add troubleshooting tips if applicable

5. **Security**
   - Never commit secrets or credentials
   - Use placeholders for sensitive values (e.g., `YOUR_API_KEY_HERE`)
   - Document which values need to be replaced
   - Consider using environment variables or secret managers

### Example Directory Structure

```
my-service/
├── README.md
├── config/
│   ├── example.yaml
│   └── template.json
├── scripts/
│   ├── setup.sh
│   └── deploy.sh
└── docs/
    └── advanced-usage.md
```

## Code Style

- Use clear, descriptive names for files and directories
- Include comments in configuration files
- Follow existing patterns in the repository
- Keep configurations generic and reusable

## Pull Request Process

1. Fork the repository
2. Create a new branch for your changes
3. Add your service setup following the guidelines above
4. Update the main README.md to include your service in the list
5. Commit your changes with clear, descriptive messages
6. Submit a pull request with a description of your addition

## Questions?

If you have questions or need help, please open an issue in the repository.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
