# Install

## Requirements

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Python 3](https://www.python.org/downloads/)
- [pip3](https://pip.pypa.io/en/stable/installation/)
- [pre-commit hook support](#install-pre-commit-hook-support)
- [make](https://www.gnu.org/software/make/)

### Install pre-commit hook support

```bash
pip install pre-commit
```

Then you can validate installed hooks with:

```bash
pre-commit run --all-files
```

## Usage
You can use the Makefile to deploy the whole infrastructure.

```bash
make deploy
```

## TODO

- [ ] Add observability (Monitoring, Logging, Tracing)
- [ ] Add more variables to customize the deployment
- [ ] Split, in each module, the resources in different files
