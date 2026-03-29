#!/usr/bin/env python3
"""
GEB Score Computation

Reads judge output (scores.yml) and computes aggregate scores.

Scoring formula:
  per_scenario = (criteria_passed / criteria_total) * comparison_weight
    BETTER = 1.2
    SAME   = 0.8  (no improvement = wasting tokens)
    WORSE  = 0.0

  aggregate = mean(all per_scenario scores)

Usage:
  python3 tests/score.py tests/results/<timestamp>/scores.yml
  python3 tests/score.py tests/results/<timestamp>/scores.yml --json
  python3 tests/score.py tests/results/<timestamp>/scores.yml --baseline tests/results/<baseline>/scores.yml
"""

import sys
import re
import json
import yaml
from pathlib import Path

COMPARISON_WEIGHTS = {
    "BETTER": 1.2,
    "SAME": 0.8,
    "WORSE": 0.0,
}

DEFAULT_SKILL = "prelude"


def load_skill_map(scores_path: Path) -> dict:
    """Build a name->skill map from tests/scenarios.yml for fallback lookup."""
    skill_map = {}
    # scenarios.yml lives in tests/ — same dir as score.py
    # scores_path is tests/results/<ts>/scores.yml, so .parent.parent.parent = tests/
    scenarios_yml = scores_path.parent.parent.parent / "scenarios.yml"
    if not scenarios_yml.exists():
        # Fallback: relative to the script itself
        scenarios_yml = Path(__file__).parent / "scenarios.yml"
    if scenarios_yml.exists():
        with open(scenarios_yml) as f:
            scenarios = yaml.safe_load(f)
        if isinstance(scenarios, list):
            for s in scenarios:
                name = s.get("name", "")
                skill = s.get("skill", DEFAULT_SKILL)
                if name:
                    skill_map[name] = skill
    return skill_map


def parse_judge_output(raw: str) -> dict:
    """Extract structured data from judge YAML output."""
    result = {
        "criteria_passed": 0,
        "criteria_total": 0,
        "fail_patterns_triggered": 0,
        "comparison": "SAME",
        "pass_rate": 0.0,
    }

    # Try to find the overall section
    overall_match = re.search(
        r"criteria_passed:\s*(\d+).*?"
        r"criteria_total:\s*(\d+).*?"
        r"fail_patterns_triggered:\s*(\d+).*?"
        r"comparison:\s*(BETTER|SAME|WORSE).*?"
        r"pass_rate:\s*([\d.]+)",
        raw,
        re.DOTALL,
    )

    if overall_match:
        result["criteria_passed"] = int(overall_match.group(1))
        result["criteria_total"] = int(overall_match.group(2))
        result["fail_patterns_triggered"] = int(overall_match.group(3))
        result["comparison"] = overall_match.group(4)
        result["pass_rate"] = float(overall_match.group(5))
    else:
        # Fallback: count PASS/FAIL occurrences
        passes = len(re.findall(r"result:\s*PASS", raw))
        fails = len(re.findall(r"result:\s*FAIL", raw))
        total = passes + fails
        result["criteria_passed"] = passes
        result["criteria_total"] = total if total > 0 else 1
        result["pass_rate"] = passes / max(total, 1)

        # Try to find comparison
        comp_match = re.search(r"comparison:\s*(BETTER|SAME|WORSE)", raw)
        if comp_match:
            result["comparison"] = comp_match.group(1)

        # Count triggered fail patterns
        triggered = len(re.findall(r"found:\s*true", raw, re.IGNORECASE))
        result["fail_patterns_triggered"] = triggered

    return result


def compute_scenario_score(parsed: dict) -> float:
    """Compute weighted score for a single scenario."""
    if parsed["criteria_total"] == 0:
        return 0.0

    base = parsed["criteria_passed"] / parsed["criteria_total"]

    # Penalize triggered fail patterns
    if parsed["fail_patterns_triggered"] > 0:
        penalty = parsed["fail_patterns_triggered"] * 0.1
        base = max(0.0, base - penalty)

    weight = COMPARISON_WEIGHTS.get(parsed["comparison"], 0.8)
    return round(base * weight, 4)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tests/score.py <scores.yml> [--json]")
        sys.exit(1)

    scores_path = Path(sys.argv[1])
    output_json = "--json" in sys.argv

    # Parse --baseline flag
    baseline_path = None
    if "--baseline" in sys.argv:
        idx = sys.argv.index("--baseline")
        if idx + 1 < len(sys.argv):
            baseline_path = Path(sys.argv[idx + 1])

    if not scores_path.exists():
        print(f"Error: {scores_path} not found")
        sys.exit(1)

    with open(scores_path) as f:
        data = yaml.safe_load(f)

    # Load baseline WORSE scenarios for regression comparison
    baseline_worse = set()
    if baseline_path and baseline_path.exists():
        with open(baseline_path) as f:
            baseline_data = yaml.safe_load(f)
        for scenario in baseline_data.get("scenarios", []):
            judge_raw = scenario.get("judge_output", "")
            parsed = parse_judge_output(judge_raw)
            if parsed["comparison"] == "WORSE":
                baseline_worse.add(scenario.get("name", ""))

    scenarios = data.get("scenarios", [])
    if not scenarios:
        print("No scenarios found in scores file")
        sys.exit(1)

    # Build skill lookup for fallback when skill is missing from scores.yml entries
    skill_map = load_skill_map(scores_path)

    results = []
    category_scores = {}
    skill_scores = {}

    for scenario in scenarios:
        name = scenario.get("name", "unknown")
        category = scenario.get("category", "unknown")
        skill = scenario.get("skill") or skill_map.get(name, DEFAULT_SKILL)
        judge_raw = scenario.get("judge_output", "")

        parsed = parse_judge_output(judge_raw)
        score = compute_scenario_score(parsed)

        results.append({
            "name": name,
            "category": category,
            "skill": skill,
            "score": score,
            "comparison": parsed["comparison"],
            "pass_rate": parsed["pass_rate"],
            "criteria_passed": parsed["criteria_passed"],
            "criteria_total": parsed["criteria_total"],
            "fail_patterns_triggered": parsed["fail_patterns_triggered"],
        })

        if category not in category_scores:
            category_scores[category] = []
        category_scores[category].append(score)

        if skill not in skill_scores:
            skill_scores[skill] = []
        skill_scores[skill].append(score)

    # Aggregate
    all_scores = [r["score"] for r in results]
    aggregate = round(sum(all_scores) / len(all_scores), 4) if all_scores else 0.0

    # Check for NEW regressions only (scenarios that became WORSE but weren't WORSE in baseline)
    all_worse = [r["name"] for r in results if r["comparison"] == "WORSE"]
    if baseline_worse:
        regressions = [name for name in all_worse if name not in baseline_worse]
    else:
        regressions = all_worse

    # Category averages
    category_averages = {
        cat: round(sum(scores) / len(scores), 4)
        for cat, scores in category_scores.items()
    }

    # Skill averages
    skill_averages = {
        sk: round(sum(scores) / len(scores), 4)
        for sk, scores in skill_scores.items()
    }

    summary = {
        "aggregate_score": aggregate,
        "total_scenarios": len(results),
        "regressions": regressions,
        "category_scores": category_averages,
        "skill_scores": skill_averages,
        "scenarios": results,
    }

    if output_json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"\n{'='*60}")
        print(f"  GEB Score Report")
        print(f"{'='*60}")
        print(f"  Aggregate Score: {aggregate:.4f}")
        print(f"  Scenarios:       {len(results)}")
        print(f"  Regressions:     {len(regressions)}")
        print()
        print(f"  Category Scores:")
        for cat, avg in sorted(category_averages.items()):
            bar = "█" * int(avg * 20) + "░" * (20 - int(avg * 20))
            print(f"    {cat:12s}  {bar}  {avg:.4f}")
        print()

        # Compute max skill name length for alignment
        max_skill_len = max((len(sk) for sk in skill_averages), default=12)
        print(f"  Skill Scores:")
        for sk, avg in sorted(skill_averages.items()):
            bar = "█" * int(avg * 20) + "░" * (20 - int(avg * 20))
            print(f"    {sk:{max_skill_len}s}  {bar}  {avg:.4f}")
        print()

        if regressions:
            print(f"  ⚠ Regressions:")
            for r in regressions:
                print(f"    - {r}")
            print()

        print(f"  Per-Scenario Detail:")
        for r in results:
            status = "✓" if r["comparison"] == "BETTER" else ("✗" if r["comparison"] == "WORSE" else "~")
            skill_tag = f"[{r['skill']}]"
            print(f"    {status} {r['name']:40s}  {skill_tag:14s}  {r['score']:.4f}  ({r['comparison']}, {r['criteria_passed']}/{r['criteria_total']} criteria)")
        print()

    # Write summary to results dir
    results_dir = scores_path.parent
    summary_path = results_dir / "summary.json"
    with open(summary_path, "w") as f:
        json.dump(summary, f, indent=2)
    if not output_json:
        print(f"  Summary saved to: {summary_path}")


if __name__ == "__main__":
    main()
