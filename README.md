# 3-Tier PERN Stack Deployment on AWS: Engineering Journey & Theory

A comprehensive documentation of building, automating, and deploying a production-grade 3-tier **PERN stack** (PostgreSQL, Express, React, Node.js) from scratch using modern DevOps practices, Infrastructure as Code, and configuration management.
## 📊 Architecture Diagram

```text
                               +-----------------------+
                               |     Control Node      |
                               |  (Ansible & Terraform)|
                               +-----------+-----------+
                                           |
                    +----------------------+----------------------+
                    |                      |                      |
                    v                      v                      v
          +-------------------+  +-------------------+  +-------------------+
          |      Node 1       |  |      Node 2       |  |      Node 3       |
          |  Database Tier    |  |   Backend Tier    |  |   Frontend Tier   |
          |  (PostgreSQL)     |  |  (Node.js/Express)|  |  (React & Nginx)  |
          |    Port: 5432     |  |    Port: 5000     |  |    Port: 3000     |
          +-------------------+  +-------------------+  +-------------------+
                    ^                      ^                      ^
                    |                      |                      |
                    +---(Private IP)-------+---(Public IP)--------+
                                        (AWS VPC)

---
```
## Table of Contents
1. [Project Philosophy & Core Concepts](#project-philosophy--core-concepts)
2. [Step-by-Step Engineering Journey & Theoretical Breakdown](#step-by-step-engineering-journey--theoretical-breakdown)
   - Phase 1: Infrastructure Provisioning (Terraform)
   - Phase 2: Control Node & Dynamic Inventory Setup (Ansible)
   - Phase 3: Multi-OS Containerization & Environment Orchestration
   - Phase 4: Network Isolation & Security
3. [Key DevOps Challenges Overcome](#key-devos-challenges-overcome)

---

## Project Philosophy & Core Concepts

Traditional deployments often rely on manual configuration, static IP addresses, and tribal knowledge, which quickly lead to configuration drift and fragile environments. This project was designed to solve those challenges by implementing two pillars of modern Cloud Engineering:

* **Infrastructure as Code (IaC):** Instead of manually clicking through the AWS Management Console, Terraform treats infrastructure as version-controlled code. This guarantees reproducibility—meaning the entire cloud environment can be spun up or destroyed identically with a single command.
* **Idempotent Configuration Management:** Ansible ensures that target servers are brought to a desired state safely. Running an Ansible playbook multiple times yields the same stable result without duplicating resources or breaking active services.

---

## Step-by-Step Engineering Journey & Theoretical Breakdown

### Phase 1: Infrastructure Provisioning (Terraform)
* **The Theory:** Cloud environments require predictable networking and compute boundaries. We used Terraform to declare an isolated architecture inside AWS's default VPC. 
* **What we did:** 
  * Defined multi-node EC2 instances (`node1` for the database, `node2` for the backend, `node3` for the frontend, and a dedicated control node).
  * Created a modular security group (`ansible_lab_sg`) to enforce strict network access, explicitly exposing ports **22 (SSH)**, **80 (HTTP)**, **3000 (React)**, **5000 (Node.js)**, and **5432 (PostgreSQL)** through in-place updates.

### Phase 2: Control Node & Dynamic Inventory Setup (Ansible)
* **The Theory:** Hardcoding IP addresses in configuration files is an anti-pattern because cloud servers receive dynamic IPs upon creation or reboot. We decoupled our automation from static IPs by utilizing Ansible's dynamic inventory capabilities.
* **What we did:**
  * Configured the control node by installing Python's package manager (`pip`) and the `boto3` SDK, allowing Ansible to natively query the AWS API.
  * Created an `aws_ec2.yml` dynamic inventory plugin configuration and assigned appropriate IAM roles to EC2 instances so they could securely discover each other's metadata.

### Phase 3: Multi-OS Containerization & Environment Orchestration
* **The Theory:** Microservices architecture requires separating concerns across isolated tiers. Containerization via Docker ensures that application dependencies (Node runtimes, React build tools, PostgreSQL engines) are bundled immutably, running identically in development and production.
* **What we did:**
  * Installed Docker uniformly across worker nodes spanning different Linux distributions—coordinating Red Hat-based systems (`dnf` on Amazon Linux for Nodes 1 & 2) and Debian-based systems (`apt` on Ubuntu for Node 3).
  * Cloned our codebase safely into temporary directories on the control node, stripping out unnecessary assets before distributing code fragments to worker nodes.
  * Deployed the **PostgreSQL database container** on Node 1 (`database.yml`), handling persistent volume mounting and secure environment variables.
  * Deployed the **Express REST API container** on Node 2 (`backend.yml`), linking it dynamically to the database.

### Phase 4: Dynamic Service Discovery & Frontend Integration
* **The Theory:** In a distributed 3-tier architecture, upstream services must pass their addresses to downstream consumers (e.g., the React frontend needs to know where the Express backend lives at compile/runtime). 
* **What we did:**
  * Leveraged Ansible's `hostvars` object to programmatically extract the private and public IP addresses of upstream nodes on the fly.
  * Injected the backend's public IP address directly into the React build configuration (`REACT_APP_BASE_URL`), ensuring the single-page application communicates seamlessly with the REST API regardless of infrastructure teardowns or IP reallocations.

