from typing import NamedTuple, Self
from BaseClasses import Item, ItemClassification
from worlds.AutoWorld import World
from .common import *
from .options import BKSim_Options

class BKSim_Item(Item):
    game = game_name
    def copy(self) -> Self:
        return BKSim_Item(self.name, self.classification, self.code, self.player)
class ItemInfo(NamedTuple):
    name: str
    flag: ItemClassification
item_table = [
    ItemInfo(ITEM.SHOES, ItemClassification.progression),
    ItemInfo(ITEM.BOOTS, ItemClassification.progression),
    ItemInfo(ITEM.NEWLOC, ItemClassification.progression),
    ]
item_name_to_id = {str(name): num for num,(name,_) in enumerate(item_table, 1)}

def get_item_counts(world: World) -> list[int]:
    multiworld = world.multiworld
    player = world.player
    options = world.options
    
    newloc_count: int = 0
    for item in multiworld.precollected_items[player]:
        if item.name == ITEM.NEWLOC:
            newloc_count += 1
    total_locs: int = int(options.locs_per_weather.value * 3)
    newloc_items: int = max(0, (1 if total_locs <= 3 else 2) - newloc_count)
    snow_items: int = int(total_locs / 3.0)
    shoe_items: int = total_locs - (snow_items + newloc_items)
    return [shoe_items, snow_items, newloc_items]

def create_items(world: World) -> None:
    multiworld = world.multiworld
    player = world.player
    
    counts: list[int] = get_item_counts(world)
    itempool = []
    for q in range(len(item_table)):
        data: ItemInfo = item_table[q]
        itm = BKSim_Item(data.name, data.flag, q+1, player)
        count: int = counts[q]
        itempool += [itm.copy() for _ in range(count)]
    multiworld.itempool += itempool

def create_item(name: str, player: int) -> BKSim_Item:
    itemid = item_name_to_id[name]
    _,flag = item_table[itemid-1]
    return BKSim_Item(name, flag, itemid, player)

def create_event_item(event: str, player: int) -> BKSim_Item:
    return BKSim_Item(event, ItemClassification.progression, None, player)

