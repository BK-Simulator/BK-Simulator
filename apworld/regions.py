from BaseClasses import Region
from worlds.AutoWorld import World
from .locations import location_table, BKSim_Location
from .common import *

def create_regions(world: World) -> None:
    multiworld = world.multiworld
    player = world.player
    
    for rid in RID:
        multiworld.regions.append(Region(rid, player, multiworld))
    
    locs_per_weather = world.options.locs_per_weather.value
    for locid,locinfo in enumerate(location_table, 1):
        if locinfo.index >= locs_per_weather:
            continue
        region = world.get_region(locinfo.region_id)
        if region:
            region.locations.append(BKSim_Location(player, locinfo.name, locid, region, locinfo))

