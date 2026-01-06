# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

-   In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of cocision.

## Purpose

Personal snippet library for reusable code - designed to be browsed on GitHub and copy/pasted when AI tools aren't available.

## Architecture

-   **ts/utilities/** - Pure TypeScript utility functions (no dependencies)
-   **ts/components/** - React/TSX components (shadcn-compatible)
-   **sql/** - T-SQL (SQL Server) stored procedure templates
-   **generic/** - Temporary workspace for one-off problem solving (push, use, delete)

## Design Principles

-   No build system - files are raw source meant for copy/paste
-   Each file should be self-contained and well-commented
-   Functions should have no external dependencies when possible
-   Components include both shadcn-dependent and standalone versions
