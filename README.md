# 📡 EC2 Monitoring and Alerting with CloudWatch & SNS

## 🔧 Project Overview

This project demonstrates how to configure **Amazon CloudWatch** and **Amazon SNS** to monitor an **EC2 instance's CPU utilization**. If CPU usage exceeds **60% for 6 minutes**, an **email alert** is sent using **SNS**.

> ✅ Implemented using **Terraform (IAC)** for reproducibility.

---

## 👨‍💻 Author

- **Group**: `group7`
- **Email**: mangucletus@gmail.com
- **Region**: `us-east-1`

---

## 🧱 Architecture Diagram

```text
     +-------------+         +----------------------+         +-------------------------+
     |  EC2        |  -----> | CloudWatch Alarm     | ----->  | SNS Topic               |
     | Instance    |         | (CPU > 60% for 6 min) |         | (group7-sns-topic)      |
     +-------------+         +----------------------+         +-------------------------+
                                                                    |
                                                                    v
                                                           mangucletus@gmail.com
                                                           (Email Notification)
