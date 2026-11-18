# Development

## Code review

Review isn't only for catching bugs. It keeps the team aware of how the
project is changing and builds agreement on decisions. Not every pull request
benefits from that. The author of a pull request decides whether it needs a
human review, and says so on the first line of the description, where it
shows up in email notifications:

```markdown
**Review:** needed — changes science outputs: ICON and BCON are now built with the CH4only mechanism
```

```markdown
**Review:** not needed — GitHub templates and CI only; merging Thursday unless someone objects
```

Always give a reason. The reason lets everyone else check the decision at a
glance, and shows over time whether these categories need adjusting.

The lists below are a guide, not rules, and some judgement is still needed.
When a change doesn't clearly fit, ask: would the rest of the team want to
know about this, or have a say in it? If so, it needs review.

### What counts as science outputs here

This repository builds the CMAQ libraries and tools (I/O API, PARIO, STENEX,
MCIP, ICON, BCON) and the `CH4only` mechanism into the `openmethane/cmaq`
Docker image, which CMAQ-Adjoint builds on. Its science outputs are what
those tools produce, and what the model built on them produces. A change
affects them if it changes:

- model or tool source code that runs, such as MCIP's reading of WRF output
- the `CH4only` mechanism, or the ICON and BCON profile data
- compilers, compiler flags or library versions, including a new base image,
  since these can change the numbers a build produces

### Review needed

- **Changes to science outputs**, as described above, however small the fix
  that causes them.
- **Refactors that change structure or behaviour across more than one file.**
- **New concepts or features**, including new tools, mechanisms, input
  formats and methodology decisions.
- **Documentation changes.** If something is worth documenting, it's worth
  the rest of the team knowing about it and agreeing with it. This doesn't
  include fixes to typos, grammar or formatting, which are mechanical changes.
- **Changes that make a build or production run fail, or stop failing, where
  it didn't before**, including builds of CMAQ-Adjoint on top of this image.
  Make sure whoever looks after production runs knows about these.

### Review not needed

- **Infrastructure changes** made by the person who looks after the
  infrastructure.
- **Mechanical changes**, such as small corrections and bug fixes whose
  correctness is established by tests, tool-generated changes such as
  running a formatter, and fixes to typos, grammar or formatting in
  documentation. Being mechanical is what matters here, not size: a
  formatter run that touches every file is still mechanical.
- **Minor or patch dependency updates.** Major version updates need review.
- **Small changes to logging, warnings, CI and project settings.**

### Science code isn't the same as science outputs

A change can touch build scripts or model code without changing any outputs.
For example, it can rename a build directory, or fix a crash in a path that
never produced results. These changes don't need review, but the reason has
to give the evidence that the outputs don't change, not just say so. If you
can't write that sentence, choose "needed".

The tests in this repository check that MCIP, ICON and BCON run and write a
non-empty file. They don't check the values in it, so "tests pass" isn't
evidence that outputs are unchanged.

### Agent review before a pull request

If you use an agent such as Claude Code to prepare a change, `CLAUDE.md`
asks it to review anything that isn't mechanical with a fresh reviewer
(`.claude/agents/reviewer.md`) before it opens the pull request. The agent
fixes clear problems itself and brings anything else to you. For riskier
changes it offers a second, independent review. Each review costs tokens, so
you can tell the agent to skip it. This is part of preparing the change, not
a substitute for human review: it doesn't change whether a pull request needs
review.

### Not needed doesn't mean merged immediately

For a "not needed" pull request, say when you'll merge it. This gives
everyone a chance to ask for a review before then. Anyone can switch a pull
request to "needed", and then it waits for a review as usual.

### Examples

| Pull request | First line |
|---|---|
| [#2](https://github.com/openmethane/CMAQ/pull/2) | **Review:** not needed — GitHub issue and pull request templates, and a CI workflow that builds the image; no model code or build flags change |
| [#6](https://github.com/openmethane/CMAQ/pull/6) | **Review:** not needed — bug fix: build directories no longer include the host kernel version, which broke builds on other kernels; only paths change, not compiler flags or sources |
| [#1](https://github.com/openmethane/CMAQ/pull/1) | **Review:** needed — new feature: building CMAQ in Docker, with PARIO and STENEX downgraded for CMAQ-Adjoint and WRFv4 support added to MCIP |
| [#3](https://github.com/openmethane/CMAQ/pull/3) | **Review:** needed — changes science outputs: ICON and BCON are now built with the CH4only mechanism and its profiles |
| [#4](https://github.com/openmethane/CMAQ/pull/4) | **Review:** needed — documentation and a licensing decision: an MIT license based on CMAQ 5.4, and re-versioning to 1.0 |
| [#7](https://github.com/openmethane/CMAQ/pull/7) | **Review:** needed — changes the compiler: a Debian trixie base image brings GCC 14 and new C flags for every binary, so outputs may change |

#6 fixed a build failure for anyone on a different kernel from the GitHub
runners, so although it doesn't need review, whoever builds CMAQ-Adjoint
should still hear about it.
