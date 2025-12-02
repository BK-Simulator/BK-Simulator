from worlds.AutoWorld import World
from BaseClasses import Location, Entrance
from ..generic.Rules import set_rule, add_rule
from .common import *
from .locations import BKSim_Location
from typing import Optional

def set_rules(world: World) -> None:
    multiworld = world.multiworld
    player = world.player
    options = world.options
    
    if True: # Region connecting
        def connect_region(r1: RID, r2: RID, rule: Optional[callable] = None) -> None:
            if rule:
                world.get_region(r1).connect(connecting_region = world.get_region(r2), rule = rule)
            else:
                world.get_region(r1).connect(connecting_region = world.get_region(r2))
        connect_region(RID.HOME, RID.SUNNY)
        connect_region(RID.HOME, RID.RAINY)
        connect_region(RID.HOME, RID.SNOWY, lambda state: state.has(ITEM.BOOTS, player))
    
    locs_list: list[BKSim_Location] = multiworld.get_locations(player)
    loc_count = options.locs_per_weather.value
    max_rules = []
    for loc in locs_list:
        if loc.info.region_id == RID.SUNNY:
            if loc.info.index == 0:
                continue
            rule = lambda state, idx=loc.info.index: state.has(ITEM.SHOES, player, idx / 2)
            if loc.info.index == loc_count-1:
                max_rules.append(rule)
            set_rule(loc, rule)
        elif loc.info.region_id == RID.RAINY:
            rule = lambda state, idx=loc.info.index: (state.has(ITEM.SHOES, player, (idx / 2) + 1) and state.has(ITEM.NEWLOC, player)) or state.has(ITEM.SHOES, player, idx)
            if loc.info.index == loc_count-1:
                max_rules.append(rule)
            set_rule(loc, rule)
        elif loc.info.region_id == RID.SNOWY:
            rule = lambda state, idx=loc.info.index: state.has(ITEM.BOOTS, player, (idx / 2) + 1)
            if loc.info.index == loc_count-1:
                max_rules.append(rule)
            set_rule(loc, rule)
    
    multiworld.completion_condition[player] = lambda state: all(rule(state) for rule in max_rules)

