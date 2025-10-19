when not defined(js):
  static:
    doAssert false, "Build with the JS backend: nim js -d:release -o:main.js <src>"

import std/[strformat, strutils]
import karax/[karax, karaxdsl, vdom]

type Field = enum
  fBallWeight
  fBallCount
  fWaterPct
  fSaltPct
  fYeastPct
  fSugarPct
  fOilPct

var state: array[Field, string] = [
  fBallWeight: "320",
  fBallCount: "3",
  fWaterPct: "62",
  fSaltPct: "1.5",
  fYeastPct: "0.5",
  fSugarPct: "2",
  fOilPct: "2",
]

func toFloat(s: string): float =
  if s.len == 0:
    0.0
  else:
    parseFloat(s)

func toPct(s: string): float =
  toFloat(s) / 100.0

func toStr(x: float): string =
  formatFloat(x, ffDecimal, 1)

# Inputs of type = "number" cause issues with reverse rendering, so we use
# "text" inputs instead and sanitize manually
func sanitize(s: string): string =
  for ch in s:
    if ch in {'0' .. '9', '.'}:
      result.add(ch)
    elif ch == ',':
      result.add('.') # standardize decimal point

# Reusable input field node
proc inputNode(label, key, current: string, field: Field): VNode =
  buildHtml(tdiv):
    label:
      text label
    input(
      key = key,
      type = "text",
      inputmode = "numeric",
      autocomplete = "off",
      value = current,
    ):
      proc oninput(ev: Event, n: VNode) =
        let val = sanitize($value(n))
        if val != current:
          state[field] = val

proc render(): VNode =
  let
    targetTotal = toFloat(state[fBallWeight]) * toFloat(state[fBallCount])
    sumPct =
      toPct(state[fWaterPct]) + toPct(state[fSaltPct]) + toPct(state[fYeastPct]) +
      toPct(state[fSugarPct]) + toPct(state[fOilPct])
    flour = targetTotal / (1.0 + sumPct)
    water = flour * toPct(state[fWaterPct])
    salt = flour * toPct(state[fSaltPct])
    yeast = flour * toPct(state[fYeastPct])
    sugar = flour * toPct(state[fSugarPct])
    oil = flour * toPct(state[fOilPct])

  buildHtml(tdiv):
    nav(role = "banner"):
      tdiv(class = "container"):
        hgroup:
          h1:
            text "Pizza Dough Calculator"
          p:
            text "Baker’s percentages"

    main(role = "main"):
      article:
        header:
          h2:
            text "Inputs"
        tdiv(class = "grid"):
          inputNode(
            "Single dough ball (g)", "ballWeight", state[fBallWeight], fBallWeight
          )
          inputNode("Number of dough balls", "ballCount", state[fBallCount], fBallCount)
          inputNode("Hydration %", "waterPct", state[fWaterPct], fWaterPct)
          inputNode("Salt %", "saltPct", state[fSaltPct], fSaltPct)
          inputNode("Yeast %", "yeastPct", state[fYeastPct], fYeastPct)
          inputNode("Sugar %", "sugarPct", state[fSugarPct], fSugarPct)
          inputNode("Oil %", "oilPct", state[fOilPct], fOilPct)

      article:
        header:
          h2:
            text "Output"

        table(role = "grid"):
          thead:
            tr:
              th:
                text "Ingredient"
              th:
                text "Percent"
              th:
                text "Grams"
          tbody:
            tr:
              td:
                text "Flour"
              td:
                text "100%"
              td:
                text toStr(flour)
            tr:
              td:
                text "Water"
              td:
                text fmt "{state[fWaterPct]} %"
              td:
                text toStr(water)
            tr:
              td:
                text "Salt"
              td:
                text fmt "{state[fSaltPct]} %"
              td:
                text toStr(salt)
            tr:
              td:
                text "Yeast"
              td:
                text fmt "{state[fYeastPct]} %"
              td:
                text toStr(yeast)
            tr:
              td:
                text "Sugar"
              td:
                text fmt"{state[fSugarPct]} %"
              td:
                text toStr(sugar)
            tr:
              td:
                text "Oil"
              td:
                text fmt "{state[fOilPct]} %"
              td:
                text toStr(oil)
          tfoot:
            tr:
              th:
                text "Total dough"
              th:
                text ""
              th:
                text fmt "{toStr(targetTotal)} g"

        details:
          summary:
            text "Batch summary"
          ul:
            li:
              text fmt"Single ball: {toStr(toFloat(state[fBallWeight]))} g"
            li:
              text fmt"Count: {state[fBallCount]}"

setRenderer render
