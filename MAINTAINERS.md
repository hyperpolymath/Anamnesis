# Maintainers

This document lists the current maintainers of the Anamnesis project and describes the maintainer role.

## Current Maintainers

### Project Founder & Lead

- **Hyperpolymath** ([@Hyperpolymath](https://github.com/Hyperpolymath))
  - **Role**: Project Founder, Lead Developer, Architect
  - **Responsibilities**: Overall direction, architecture, major decisions, release management
  - **Focus Areas**: All components (multi-language expertise)
  - **Contact**: [EMAIL_TO_BE_ADDED]
  - **Status**: Active
  - **Since**: 2025-11-22

### Component Maintainers

_(None yet - accepting applications! See "Becoming a Maintainer" below)_

**Future roles** (as project grows):

- **Parser (OCaml)**: Maintainer needed
- **Orchestrator (Elixir)**: Maintainer needed
- **Reasoning (λProlog)**: Maintainer needed
- **Learning (Julia)**: Maintainer needed
- **Visualization (AffineScript)**: Maintainer needed
- **Documentation**: Maintainer needed
- **Community**: Maintainer needed

## Maintainer Responsibilities

Maintainers are **trusted contributors** who have demonstrated:

- Technical expertise in one or more components
- Commitment to the project's values (see CODE_OF_CONDUCT.md)
- Consistent high-quality contributions
- Ability to mentor and review others' work
- Alignment with Palimpsest Principles (reversibility, emotional safety, distributed authority)

### Core Responsibilities

1. **Code Review**
   - Review pull requests in your area of expertise
   - Provide constructive, timely feedback
   - Approve PRs that meet quality standards
   - Request changes when necessary

2. **Issue Triage**
   - Respond to new issues within 48 hours
   - Label issues appropriately (`bug`, `feature`, `help wanted`, etc.)
   - Close duplicates, stale issues, or off-topic requests
   - Escalate security issues to SECURITY.md process

3. **Mentorship**
   - Help newcomers get started
   - Answer questions in GitHub Discussions
   - Guide contributors through their first PRs
   - Share knowledge in documentation

4. **Roadmap Participation**
   - Contribute to milestone planning
   - Prioritize issues and features
   - Vote on major decisions (RFCs, breaking changes)
   - Attend maintainer meetings (when established)

5. **Release Management** (Lead Maintainer)
   - Coordinate releases
   - Update CHANGELOG.md
   - Tag versions (semantic versioning)
   - Publish release notes

6. **Community Building**
   - Enforce Code of Conduct fairly and consistently
   - Foster inclusive, welcoming environment
   - Recognize contributions (big and small)
   - Represent the project at conferences/events (optional)

### Authority & Decision-Making

Maintainers have:
- **Write access** to the repository (direct push to feature branches, not `main`)
- **Merge authority** for PRs in their domain
- **Veto power** on changes that violate project principles (with explanation)
- **Vote** on major decisions (1 vote per maintainer, simple majority)

**Consensus vs. Voting**:
- Prefer **consensus** (everyone agrees or is willing to try)
- Use **voting** only when consensus can't be reached
- Lead Maintainer has **tiebreaker vote**

**Escalation**:
- If maintainers disagree, discuss in private maintainer channel
- If still stuck, escalate to Lead Maintainer for final call
- Document decision rationale in GitHub Discussion or RFC

## Becoming a Maintainer

### Path to Maintainership

1. **Contributor** (3+ merged PRs)
   - Demonstrate technical competence
   - Follow contribution guidelines (CONTRIBUTING.md)
   - Engage positively with community

2. **Collaborator** (10+ merged PRs, 6+ months activity)
   - Sustained contribution over time
   - Expertise in specific component or domain
   - Help others (code reviews, discussions, mentorship)

3. **Maintainer Nomination**
   - Any current maintainer can nominate
   - Nominee must accept nomination
   - 2-week discussion period
   - Maintainer vote (simple majority approval)

### Requirements

- **Technical Expertise**: Deep knowledge of at least one component
- **Contribution History**: 10+ merged PRs, 6+ months activity
- **Community Engagement**: Active in discussions, helpful to newcomers
- **Code of Conduct**: Exemplary adherence, models positive behavior
- **Availability**: Commit to 4-8 hours/month minimum
- **Communication**: Responsive (48-hour response time for critical issues)

### Nomination Process

1. **Nomination**: Maintainer opens private discussion with other maintainers
2. **Notification**: Nominee informed and invited to accept
3. **Public Announcement**: If accepted, nominee announced in GitHub Discussion
4. **Community Feedback**: 2-week period for questions/concerns
5. **Vote**: Maintainers vote (simple majority, must be public with rationale)
6. **Onboarding**: New maintainer granted access, added to MAINTAINERS.md
7. **Announcement**: Public welcome announcement

### Onboarding for New Maintainers

- Add to GitHub team with write access
- Add to private maintainer communication channel
- Review maintainer responsibilities and authority
- Pair with experienced maintainer for first 2 weeks
- Introduce in GitHub Discussions and README

## Stepping Down

Maintainers may step down for any reason:

- **Voluntary**: Life changes, time constraints, new priorities
- **Inactive**: No activity for 6+ months (automatic removal with notification)
- **Forced**: Code of Conduct violation, abuse of authority (vote required)

### Process

1. **Notification**: Email other maintainers (for voluntary)
2. **Transition**: Hand off active responsibilities
3. **Access Revocation**: Remove write access, maintainer team membership
4. **Recognition**: Move to "Emeritus Maintainers" section below
5. **Announcement**: Public thank-you announcement

Emeritus maintainers may return if circumstances change (simplified re-nomination).

## Emeritus Maintainers

_(None yet - this section will recognize past maintainers who stepped down gracefully)_

## Maintainer Meetings

**Not yet established.** As the project grows, we'll hold:

- **Monthly maintainer sync**: 1 hour, planning and retrospective
- **Quarterly roadmap planning**: 2 hours, set priorities for next quarter
- **Ad-hoc discussions**: As needed for urgent decisions

Meetings will be:
- **Scheduled in advance** (with calendar invite)
- **Recorded** (for transparency, unless discussing sensitive topics)
- **Summarized** (meeting notes published in GitHub Discussions)

## Communication Channels

### Public

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Q&A, ideas, announcements
- **GitHub PRs**: Code review, technical discussion

### Maintainer-Only (Future)

- **Private maintainer channel**: TBD (Discord, Slack, or Matrix)
- **Email list**: [MAINTAINERS_EMAIL_TO_BE_ADDED]

### Transparency

Maintainer discussions are **public by default** unless:
- Security vulnerabilities (pre-disclosure)
- Code of Conduct enforcement
- Personal matters (health, family, etc.)
- Legal issues

## Conflict Resolution

If maintainers have conflicts:

1. **Direct communication**: Talk it out, assume good faith
2. **Mediation**: Another maintainer mediates discussion
3. **Lead Maintainer decision**: Final call if mediation fails
4. **Community input**: For major disagreements, seek community feedback

## Questions?

- **About maintainer role**: Open a GitHub Discussion (Q&A)
- **Nominate yourself or someone**: Email [MAINTAINERS_EMAIL_TO_BE_ADDED]
- **Report maintainer conduct issues**: See CODE_OF_CONDUCT.md

---

**Last updated**: 2025-11-22
**Next review**: Q2 2026 (or when 3+ maintainers active)
