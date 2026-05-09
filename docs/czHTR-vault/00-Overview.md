---
tags: [overview, project]
updated: 2026-05-09
---

# czHTR — Property Management System

## Mô tả
Hệ thống quản lý nhà trọ / chung cư mini. Hỗ trợ 3 roles: **ADMIN**, **TENANT**, **TECHNICIAN**.

## Tech Stack
| Layer | Tech |
|---|---|
| Backend | Java 21, Spring Boot 3.x, Maven |
| Security | Spring Security + JWT (access + refresh) |
| DB | PostgreSQL 16 |
| Cache | Redis (OTP, session) |
| Files | MinIO |
| Scheduler | Quartz |
| Payment | PayOS SDK |
| Email | JavaMailSender + Thymeleaf |
| Frontend | React 18 + TypeScript + Vite |
| UI | shadcn/ui + Tailwind CSS |
| State | Zustand |
| Data | TanStack Query (React Query) |

## Project Paths
- Backend: `D:\Code\cz-HTR\htr-backend` — package `chez1s.htrbackend`
- Frontend: `D:\Code\cz-HTR\htr-frontend\src`
- Plan: `master-plan.md`

## Related Notes
- [[01-Architecture]] — chi tiết kiến trúc BE/FE
- [[02-State]] — trạng thái hiện tại & roadmap
- [[03-Backend]] — entities, DTOs, services, controllers
- [[04-Frontend]] — pages, components, hooks, API modules
- [[05-API-Reference]] — tất cả endpoints
- [[06-Roadmap]] — các tính năng chưa làm
