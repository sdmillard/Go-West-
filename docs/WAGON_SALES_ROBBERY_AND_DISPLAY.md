# Wagon sales, robbery demands and resizing

## Selling a wagon

At an open post counter, choose **Sell Wagon / Pack**. Select what stays in the travelers' packs, including how many oxen to retain. The review shows:
- Actual walking weight and capacity.
- The wagon and goods the store will buy, within its remaining buying demand.
- Exact cash payout and whether this visit still costs a day.
- Goods and shared household gear **left behind permanently**.

Confirming sells the empty frame for half its existing base price, sells accepted leftovers at that counter's prices, keeps the selected goods and livestock, and permanently leaves the rest. It creates no recovery cache and cannot dismiss companions as guards. An older abandoned cache remains where it was. Carried remains remain carried and count toward capacity. Existing fresh/dried food identities and weights are retained correctly.

A post buys at most one wagon from this party. The sold frame enters its finite replacement stock. Buying a replacement and reselling it is a loss, not a source of money. Independence's food resale quote is capped at half its local buy quote: adding its low-priced store must not create an immediate buy-and-resell profit. Other existing post food prices remain unchanged.

## Choosing robbery demands

**Villainy > Rob > a local target** opens the existing target preview; its threat button now opens a quantity form. Nothing happens until **Make Demand** is confirmed.

Available targets expose cash, food and applicable supplies or livestock. A roadside emigrant family, or an eligible post/store, can have a wagon; traders described as traveling with packs do not automatically have one. Only a party on foot can demand one wagon. The frame provides no team, new household outfit or automatically included cargo. Choose an ox separately when one is available.

Requests are bounded by actual finite stock and previous purchases/seizures. Trader/family cash is bounded by both its crime cash box and its remaining trading purse. Preview uses existing opening/lot prices for value, not a hidden arbitrary difficulty score. A larger fraction of the target inventory lowers compliance, and demanding a wagon adds a separate resistance penalty. Existing staff, party condition, willing helpers and successful-crime/defense experience still matter. These are authored response curves, not historical compliance statistics.

On resistance the robbery grants nothing; the target can injure someone immediately, and escape/capture risks remain. On compliance, collecting uses another ordinary day and takes exactly the agreed basket. It cannot be collected twice. Hauling and wagon storage apply before the request; if deaths or injuries subsequently remove the ability to carry the goods, the party can flee rather than silently gain overweight packs.

The incident retains the fixed demand and actual goods taken. Witness reactions, trust losses, spreading reports, escape, trials and wanted encounters use the existing system. Stolen frames and other goods count toward the value used for restitution and reward postings. Existing saved robberies and study policies without custom demands retain their original fixed-loot behavior.

## Window resizing

The default is now **Fit: keep proportions**, with fractional scaling. Dragging the window therefore scales the picture continuously instead of waiting for the next whole pixel multiple.

Options also offers **Fill window: stretch to fit**, which uses any chosen aspect ratio but stretches the artwork, and **Crisp pixels: whole sizes**, which preserves the previous integer scaling and can leave wider borders. The 800x360 logical interface and nearest-neighbor art remain. This is configurable scaling rather than a rearrangement of every panel. Changing fit or travel speed does not reset a manually resized window; explicit size presets/fullscreen still control the physical window.

The new preference is saved independently of journey files. Native sale/demand/options views are rendered for visual review, and tests cover all three Window settings. Human display comfort and end-to-end difficulty remain playtest work.
