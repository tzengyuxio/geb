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
  python3 tests/score.py --multi-run tests/results/run1/scores.yml tests/results/run2/scores.yml ...
"""

import sys
import re
import json
import math
import yaml
from pathlib import Path
from collections import defaultdict

COMPARISON_WEIGHTS = {
    "BETTER": 1.2,
    "SAME": 0.8,
    "WORSE": 0.0,
}

DEFAULT_SKILL = "prelude"


def load_skill_map() -> dict:
    """Build a name->skill map from tests/scenarios.yml for fallback lookup."""
    skill_map = {}
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


def score_single_run(scores_path: Path, baseline_path=None) -> dict:
    """Score a single run, returning the summary dict."""
    with open(scores_path) as f:
        data = yaml.safe_load(f)

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
        return {"aggregate_score": 0, "total_scenarios": 0, "scenarios": [], "category_scores": {}, "skill_scores": {}, "regressions": []}

    skill_map = None
    results = []
    category_scores = {}
    skill_scores = {}

    for scenario in scenarios:
        name = scenario.get("name", "unknown")
        category = scenario.get("category", "unknown")
        skill = scenario.get("skill")
        if not skill:
            if skill_map is None:
                skill_map = load_skill_map()
            skill = skill_map.get(name, DEFAULT_SKILL)
        judge_raw = scenario.get("judge_output", "")
        parsed = parse_judge_output(judge_raw)
        score = compute_scenario_score(parsed)

        results.append({
            "name": name, "category": category, "skill": skill,
            "score": score, "comparison": parsed["comparison"],
            "pass_rate": parsed["pass_rate"],
            "criteria_passed": parsed["criteria_passed"],
            "criteria_total": parsed["criteria_total"],
            "fail_patterns_triggered": parsed["fail_patterns_triggered"],
        })

        category_scores.setdefault(category, []).append(score)
        skill_scores.setdefault(skill, []).append(score)

    all_scores = [r["score"] for r in results]
    aggregate = round(sum(all_scores) / len(all_scores), 4) if all_scores else 0.0
    all_worse = [r["name"] for r in results if r["comparison"] == "WORSE"]
    regressions = [n for n in all_worse if n not in baseline_worse] if baseline_worse else all_worse

    return {
        "aggregate_score": aggregate,
        "total_scenarios": len(results),
        "regressions": regressions,
        "category_scores": {c: round(sum(s)/len(s), 4) for c, s in category_scores.items()},
        "skill_scores": {sk: round(sum(s)/len(s), 4) for sk, s in skill_scores.items()},
        "scenarios": results,
    }


def multi_run_report(scores_paths: list, output_json: bool = False):
    """Average scores across multiple runs, reporting mean and stddev per scenario."""
    runs = []
    for p in scores_paths:
        runs.append(score_single_run(Path(p)))

    # Collect per-scenario scores across runs
    scenario_scores = defaultdict(list)
    scenario_meta = {}
    for run in runs:
        for s in run["scenarios"]:
            scenario_scores[s["name"]].append(s["score"])
            scenario_meta[s["name"]] = {"category": s["category"], "skill": s["skill"]}

    # Compute per-scenario mean and stddev
    results = []
    category_agg = defaultdict(list)
    skill_agg = defaultdict(list)
    for name, scores in sorted(scenario_scores.items()):
        mean = sum(scores) / len(scores)
        variance = sum((x - mean) ** 2 for x in scores) / len(scores) if len(scores) > 1 else 0
        stddev = math.sqrt(variance)
        meta = scenario_meta[name]
        entry = {
            "name": name,
            "category": meta["category"],
            "skill": meta["skill"],
            "mean": round(mean, 4),
            "stddev": round(stddev, 4),
            "runs": len(scores),
            "scores": [round(s, 4) for s in scores],
        }
        results.append(entry)
        category_agg[meta["category"]].append(mean)
        skill_agg[meta["skill"]].append(mean)

    all_means = [r["mean"] for r in results]
    aggregate_mean = round(sum(all_means) / len(all_means), 4) if all_means else 0

    # High variance scenarios (stddev > 0.3)
    volatile = [r for r in results if r["stddev"] > 0.3]

    summary = {
        "aggregate_mean": aggregate_mean,
        "num_runs": len(runs),
        "total_scenarios": len(results),
        "category_means": {c: round(sum(s)/len(s), 4) for c, s in category_agg.items()},
        "skill_means": {sk: round(sum(s)/len(s), 4) for sk, s in skill_agg.items()},
        "volatile_scenarios": [{"name": r["name"], "stddev": r["stddev"], "scores": r["scores"]} for r in volatile],
        "scenarios": results,
    }

    if output_json:
        print(json.dumps(summary, indent=2))
    else:
        print(f"\n{'='*60}")
        print(f"  GEB Multi-Run Score Report ({len(runs)} runs)")
        print(f"{'='*60}")
        print(f"  Aggregate Mean:  {aggregate_mean:.4f}")
        print(f"  Scenarios:       {len(results)}")
        print(f"  Volatile (σ>0.3): {len(volatile)}")
        print()

        print(f"  Category Means:")
        for cat, avg in sorted(summary["category_means"].items()):
            bar = "█" * int(avg * 20) + "░" * (20 - int(avg * 20))
            print(f"    {cat:14s}  {bar}  {avg:.4f}")
        print()

        max_skill_len = max((len(sk) for sk in summary["skill_means"]), default=12)
        print(f"  Skill Means:")
        for sk, avg in sorted(summary["skill_means"].items()):
            bar = "█" * int(avg * 20) + "░" * (20 - int(avg * 20))
            print(f"    {sk:{max_skill_len}s}  {bar}  {avg:.4f}")
        print()

        if volatile:
            print(f"  ⚠ Volatile Scenarios (σ > 0.3):")
            for v in volatile:
                scores_str = ", ".join(f"{s:.2f}" for s in v["scores"])
                print(f"    {v['name']:40s}  σ={v['stddev']:.2f}  [{scores_str}]")
            print()

        print(f"  Per-Scenario Detail:")
        for r in results:
            stability = "○" if r["stddev"] <= 0.1 else ("△" if r["stddev"] <= 0.3 else "⚡")
            skill_tag = f"[{r['skill']}]"
            print(f"    {stability} {r['name']:40s}  {skill_tag:14s}  μ={r['mean']:.4f}  σ={r['stddev']:.4f}")
        print()


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tests/score.py <scores.yml> [--json]")
        print("       python3 tests/score.py --multi-run <scores1.yml> <scores2.yml> ...")
        sys.exit(1)

    # Multi-run mode
    if "--multi-run" in sys.argv:
        idx = sys.argv.index("--multi-run")
        output_json = "--json" in sys.argv
        paths = [a for a in sys.argv[idx+1:] if not a.startswith("--")]
        if len(paths) < 2:
            print("Error: --multi-run requires at least 2 scores.yml paths")
            sys.exit(1)
        multi_run_report(paths, output_json)
        return

    scores_path = Path(sys.argv[1])
    output_json = "--json" in sys.argv

    baseline_path = None
    if "--baseline" in sys.argv:
        idx = sys.argv.index("--baseline")
        if idx + 1 < len(sys.argv):
            baseline_path = Path(sys.argv[idx + 1])

    if not scores_path.exists():
        print(f"Error: {scores_path} not found")
        sys.exit(1)

    summary = score_single_run(scores_path, baseline_path)
    aggregate = summary["aggregate_score"]
    results = summary["scenarios"]
    regressions = summary["regressions"]
    category_averages = summary["category_scores"]
    skill_averages = summary["skill_scores"]

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
