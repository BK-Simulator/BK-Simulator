from dataclasses import dataclass
from Options import Range, PerGameCommonOptions
from .common import *

class LocationsPerWeather(Range):
    """The total number of locations per type of weather. (There are 3 weather types)"""
    display_name = "Locations Per Weather"
    range_start = 1
    range_end = 100
    default = 3
class StartDistance(Range):
    """The distance to the closest BK at the start.
    Each 'New Location' upgrade opens a location halfway between your house and the current closest location."""
    display_name = "Start Distance"
    range_start = 50
    range_end = 5000
    default = 300
class SpeedPerUpgrade(Range):
    """The amount of speed gained for each shoe upgrade."""
    display_name = "Start Distance"
    range_start = 1
    range_end = 100
    default = 2

@dataclass
class BKSim_Options(PerGameCommonOptions):
    locs_per_weather: LocationsPerWeather
    start_distance: StartDistance
    speed_per_upgrade: SpeedPerUpgrade

options_presets = {
    "Default": {
        "locs_per_weather":  3,
        "start_distance":    300,
        "speed_per_upgrade": 2,
    },
    "Quick": {
        "locs_per_weather":  1,
        "start_distance":    100,
        "speed_per_upgrade": 5,
    },
    "Marathon": {
        "locs_per_weather":  1,
        "start_distance":    5000,
        "speed_per_upgrade": 1,
    },
    "Extra Long": {
        "locs_per_weather":  5,
        "start_distance":    5000,
        "speed_per_upgrade": 5,
    },
}
