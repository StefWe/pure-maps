# -*- coding: utf-8 -*-

# Copyright (C) 2014 Osmo Salomaa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""
Routing using MapQuest Open.

http://open.mapquestapi.com/directions/
"""

import copy
import json
import poor
import urllib.parse

CONF_DEFAULTS = {"type": "fastest"}

ICONS = { 0: "alert",
          1: "alert",
          2: "alert",
          3: "alert",
          4: "alert",
          5: "alert",
          6: "alert",
          7: "alert",
          8: "alert",
          9: "alert",
         10: "alert",
         11: "alert",
         12: "alert",
         13: "alert",
         14: "alert",
         15: "alert",
         16: "alert",
         17: "alert",
         18: "alert"}

URL = ("http://open.mapquestapi.com/directions/v2/route"
       "?key=Fmjtd%7Cluur2quy2h%2Cbn%3Do5-9aasg4"
       "&ambiguities=ignore"
       "&from={fm}"
       "&to={to}"
       "&unit=k"
       "&routeType={type}"
       "&doReverseGeocode=false"
       "&shapeFormat=cmp"
       "&generalize=5"
       "&manMaps=false")

cache = {}

def prepare_endpoint(point):
    """Return `point` as a string ready to be passed on to the router."""
    # MapQuest Open accepts both addresses and coordinates as endpoints,
    # but it doesn't seem to understand as many addresses as Nominatim.
    # Hence, let's use Nominatim and feed coordinates to MapQuest.
    if isinstance(point, str):
        results = poor.Geocoder("nominatim").geocode(point)
        with poor.util.silent(LookupError):
            point = (results[0]["x"], results[0]["y"])
    if isinstance(point, (list, tuple)):
        point = "{:.6f},{:.6f}".format(point[1], point[0])
    return urllib.parse.quote_plus(point)

def route(fm, to, params):
    """Find route and return its properties as a dictionary."""
    fm = prepare_endpoint(fm)
    to = prepare_endpoint(to)
    type = poor.conf.routers.mapquest_open.type
    url = URL.format(**locals())
    with poor.util.silent(KeyError):
        return copy.deepcopy(cache[url])
    result = json.loads(poor.util.request_url(url, "utf_8"))
    x, y = poor.util.decode_epl(result["route"]["shape"]["shapePoints"])
    maneuvers = []
    for leg in result["route"]["legs"]:
        maneuvers.extend(leg["maneuvers"])
    maneuvers = [dict(x=float(maneuver["startPoint"]["lng"]),
                      y=float(maneuver["startPoint"]["lat"]),
                      icon=ICONS.get(maneuver["turnType"], "alert"),
                      narrative=maneuver["narrative"],
                      duration=float(maneuver["time"]),
                      ) for maneuver in maneuvers]

    route = {"x": x, "y": y, "maneuvers": maneuvers}
    cache[url] = copy.deepcopy(route)
    return route
