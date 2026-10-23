# Location scenes and historical references

The western expansion now adds route-wide scenes; see [Western references](WESTERN_REFERENCES.md) for new stops and inspected period illustrations.

The user requested illustrated locations early in development, with historical pictures guiding the art where available. Nine original pixel assets now support the six route locations, town preparation, store interior and camp. `research/VISUAL_REFERENCES.json` records reference URLs, dates, inspection methods and limits.

## What informed each scene

| Scene | Evidence used | Limits and interpretation |
| --- | --- | --- |
| Independence and party preparation | [The Henry Ford, object 82.129.623 / THF102965](https://www.thehenryford.org/collections/explore/artifact/88453), circa-1853 engraving, visually inspected | Broad square, low buildings, a hip-roof/cupola silhouette, parked covered wagons and people. The print is later than 1848. Our composition/colors are original; the precise 1848 building appearance and street arrangement remain unverified |
| General store | [Old Sturbridge Village, Asa Knight Store](https://www.osv.org/building/asa-knight-store-2/), visually inspected museum interior photos | Shelving, ceramic goods, bottles, fabric, a long wooden counter and barrels. This is a preserved/interpreted New England store, with additions in 1826 and 1838–39, not an Independence shop. Used as a comparative period reference, not a verified Missouri interior. Our attendant is fictional |
| Wakarusa | [NPS Bluejacket Crossings](https://www.nps.gov/places/bluejacket-crossings-of-the-wakarusa-river.htm), including its University of Kansas archival photo, visually inspected | Wooded channel and irregular limestone ledges, rather than an open prairie bank. Photo date is not established here. Different historic Wakarusa crossings existed; our route's precise ford has not been identified. No later inn, bridge or ferry has been added |
| Kansas/Kaw | [NPS Kansas River/Pappin ferry account](https://www.nps.gov/places/kansas-river-crossing-and-pappins-ferry.htm), written description | Wide muddy water and a plank ferry platform supported by dugout-like hulls. Camera position, water stage, boat proportions and people are interpretive. This is not a traced photograph or a reconstructed river reading |
| Big Blue | [NPS Alcove Spring exhibit description](https://www.nps.gov/media/video/view.htm?id=F5FCA14D-5F5F-4251-B2BA-DD6855A66A09), 2023 interpretation | Low ridges, vegetation and a gravel ford. The river changed course after the 1903 flood; a modern view is not an unchanged 1848 channel. No Marshall ferry is shown |
| Platte | [NPS The Platte Experience](https://www.nps.gov/articles/000/the-platte-experience.htm) and Palmer's period descriptions | Broad flat river landscape, sandy channels and an island with limited trees. The exact channel pattern and viewpoint are illustrative; no mountains or later army buildings are invented |
| Elm Grove | Palmer's named campground and general camp context | Still an interpretive campground scene, not a surveyed historical view. Do not equate Palmer's Elm Grove with a particular modern park solely because the names resemble one another |
| Resting camp | General wagon-camp context; independently authored composition | A generic inter-landmark rest scene, intentionally not labelled as a documented encampment or a specific historical party |
| Greenwood (Sublette) Cutoff | NPS Oregon/California NHT descriptions of the cutoff and emigrant diaries' accounts of the dry drive, written descriptions | Rolling sage and alkali flats with no water between the Big Sandy and the Green, dead stock by the road and the Wyoming Range far to the west. The viewpoint, the train and the wreckage are composed, not a surveyed spot |
| Fort Walla Walla (Fort Nez Percés) | HBC post histories (the 1818 wooden fort burned in 1841 and was rebuilt in adobe) and descriptions of Wallula Gap and its basalt pillars, written descriptions | A mud-brick square with two corner bastions on a bare sandy bench above the Walla Walla mouth, the gap downstream. Wall height, building layout and the mat lodge are interpretive |
| Columbia raft below The Dalles | Palmer's 1845 account of rafting and canoe hire below The Dalles and NPS Oregon NHT material on the river route, written descriptions | Stepped basalt walls, firs on the Oregon side, a strong upstream wind, a wagon box lashed onto a log raft and a Chinookan canoe carrying goods. The reach shown and the waterfall's place are composed |

The first three entries use pictures that were actually viewed, not just search captions. Other scenes currently use written sources. Documented objects and terrain guide the pictures; uncertain composition and precise placement remain explicit. Contemporary captions, institutional interpretation, later depictions and our invention are not interchangeable evidence.

## Original art and implementation

`location_art.gd` paints these assets through the integer-pixel tools in `build_art.gd`. No archival photograph, museum visitor, scan, watermark, proprietary game sprite, logo or font is pasted or traced into a runtime asset. Reference media is not redistributed with the game; source URLs are retained. Viewing a museum image does not itself establish permission to redistribute that image.

- Route/camp pictures are 432 × 150 pixels. Town preparation and store pictures are 622 × 273, matching their panels without fractional resampling.
- `data/location_scenes.json` maps presentation IDs to images. `ui/location_scenes.gd` loads/caches them and provides a fallback for an unknown ID. The engine knows only location IDs, not textures.
- Arrival replaces the travel composition with a location illustration, so the animated traveling wagon is not painted over the landmark. The full-route ending retains its Oregon City scene; the old Platte endpoint is only a regression fixture.
- Party preparation and shopping are two views of the same uncommitted setup transaction. Back preserves names, month, profession and cart; only Depart charges the engine.
- Rest between landmarks shows camp. Rest at a crossing keeps the crossing illustration. Continue restores the traveling composition.
- Illustration changes do not advance time or consume simulation RNG. Future locations need a registry entry and an image; coverage checks fail if a route location lacks one.

## Next visual research

Seek closer-to-1848 Independence views, store inventories/interiors from western Missouri, stronger identification of the Elm Grove stop and the selected Wakarusa ford, and additional period ferry depictions. Replace provisional composition when stronger evidence appears. Record the depicted place/date separately from publication date and from a museum reconstruction's date. Do not introduce a later building or service merely because a good photograph exists.
