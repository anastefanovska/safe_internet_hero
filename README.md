# Safe Internet Hero

A cross-platform educational quiz game that teaches children aged 10–14 to use the internet safely and responsibly, building digital literacy and critical thinking through gamification.

## Overview

Safe Internet Hero turns online-safety education into an interactive quiz game. Children progress through themed quizzes, earn points, and unlock challenges covering cyberbullying, phishing, personal-data protection, and recognizing fake information. A reward system of badges, titles, and virtual coins — plus a leaderboard — keeps learning engaging.

## Tech Stack

- **Frontend:** Flutter (Android, iOS, and web from a single codebase)
- **Backend:** Firebase
  - Firebase Authentication — pseudonymous registration and login
  - Cloud Firestore — user profiles, questions, results, badges
  - Firebase Storage — images, icons, and short educational videos

## Architecture

The app is organized in three layers:

- **Presentation layer** — all UI elements (quiz screens, mini-games, rewards).
- **Application/logic layer** — game flow, answer checking, scoring, reward allocation, and progress tracking.
- **Data layer** — connects to Firebase services for storing and processing user data, questions, results, and media.

## Features

- **User system** — registration/login via Firebase Auth, avatar personalization, progress tracking.
- **Quiz module** — themed quizzes by difficulty, dynamic feedback, scoring and level progression.
- **Reward system** — badges and virtual coins, leaderboard with pseudonyms, achievement records.
- **Mini-games** — interactive activities to apply learned knowledge, with visual and sound effects.

## Team

- Ana Stefanovska (221100)
- Petar Trajkoski (211214)
- Iskra Markovska (223065)

Mentor: Prof. Dr. Dejan Gjorgjevikj — FINKI, Ss. Cyril and Methodius University, Skopje