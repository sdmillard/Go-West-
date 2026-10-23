"""Reproduce the partial historical basket and current outfit calculation.

Run from any directory: python research/food_cost_audit.py
Only reads repository files; prints JSON and never overwrites archived reports.
"""
import json
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))

def audit():
    evidence = read("research/FOOD_PRICE_AUDIT.json")
    basket = evidence["comparison_basket_lb"]
    pounds = sum(basket.values())
    markets = []
    for market in evidence["markets"]:
        prices = market["dollars_per_lb"]
        bounds = [sum(Decimal(str(weight)) * Decimal(prices[item][bound])
                      for item, weight in basket.items()) for bound in (0, 1)]
        markets.append({"source": market["source"], "basket_lb": pounds,
                        "basket_cost_dollars": [str(x) for x in bounds],
                        "dollars_per_lb": [str((x / pounds).quantize(Decimal("0.000001"))) for x in bounds]})
    outfit = read("data/outfitting.json")
    total = sum(x["price_cents"] * x["suggested"] for x in outfit["goods"])
    return {"markets": markets, "current_suggested_cart_cents": total,
            "cash_after_cart_cents": {x["id"]: x["cash_cents"] - total for x in outfit["professions"]},
            "limits": evidence["basket_limits"], "decision": evidence["decision"]}

if __name__ == "__main__":
    print(json.dumps(audit(), indent=2))
