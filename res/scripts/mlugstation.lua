local laneutil = require "laneutil"
local paramsutil = require "paramsutil"
local func = require "func"
local coor = require "coor"
local trackEdge = require "trackedge"
local station = require "stationlib"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {-10, -15, -20}
local angleList = {0, 15, 30, 45, 60, 75, 90}
local nbTracksLevelList = {{2, 1}, {4, 1}, {2, 2}, {4, 2}, {2, 3}, {4, 3}}

local newModel = function(m, ...)
    return {
        id = m,
        transf = coor.mul(...)
    }
end

local snapRule = function(e) return func.filter(func.seq(0, #e - 1), function(e) return e % 4 == 0 or (e - 3) % 4 == 0 end) end

local function params()
    return {
        {
            key = "nbTracks",
            name = string.format([[%s × %s]], _("Number of tracks"), _("Levels")),
            values = func.map(nbTracksLevelList, function(nl) local nb, le = table.unpack(nl) return nb .. "×" .. le end),
        },
        {
            key = "length",
            name = _("Platform length") .. "(m)",
            values = func.map(platformSegments, function(l) return _(tostring(l * station.segmentLength)) end),
            defaultIndex = 2
        },
        {
            key = "trackTypeCatenary",
            name = _("Track Type & Catenary"),
            values = {_("Normal"), _("Elec."), _("Elec.Hi-Speed"), _("Hi-Speed")},
            defaultIndex = 1
        },
        {
            key = "angle2",
            name = _("Level -2 Cross angle") .. "(°)",
            values = func.map(angleList, tostring)
        },
        {
            key = "angle3",
            name = _("Level -3 Cross angle") .. "(°)",
            values = func.map(angleList, tostring)
        },
        {
            
            key = "mirrored",
            name = _("Mirrored"),
            values = {_("None"), _("Level -2"), _("Level -3"), _("Levels -2 & -3")}
        },
        {
            key = "platformHeight",
            name = _("Depth") .. "(m)",
            values = func.map(heightList, tostring),
            defaultIndex = 1
        },
        {
            key = "tramTrackType",
            name = _("Tram Track Type"),
            values = {_("No"), _("Yes"), _("Electric")},
            defaultIndex = 0
        },
        paramsutil.makeTramTrackParam2(),
        {
            key = "entryMode",
            name = _("Entry Type"),
            values = {_("1 Mini"), _("1 Micro"), _("Mini"), _("Micro"), _("Mixed")},
            defaultIndex = 1
        },
        {
            key = "topoMode",
            name = _("Topology"),
            values = {_("Star"), _("Triangle"), _("Side by Side")}
        },
    }
end

local function addEntry(result, tram, config)
    table.insert(result.models, config.model)
    local street =
        {
            type = "STREET",
            params =
            {
                type = config.streetType,
                tramTrackType = tram
            },
            edges = config.steetEdegs,
            snapNodes = func.filter(func.seq(0, #config.steetEdegs - 1), function(n) return n % 2 == 0 end)
        }
    
    table.insert(result.edgeLists, street)
    table.insert(result.terrainAlignmentLists,
        {
            type = "EQUAL",
            faces = config.faces
        }
    )
    result.groundFaces = func.concat(result.groundFaces,
        func.mapFlatten(config.faces, function(f) return {
            {face = f, modes = {{type = "FILL", key = "industry_gravel_small_01"}}},
            {face = f, modes = {{type = "STROKE_OUTER", key = "building_paving"}}}
        } end)
)
end

local function centers(nSeg)
    return {
        {
            {x = 0, y = 0, z = 0},
            {x = 0, y = station.segmentLength * (nSeg * 0.5 - 2), z = 0},
            {x = 0, y = -station.segmentLength * (nSeg * 0.5 - 2), z = 0}
        },
        {
            {x = 0, y = 0, z = 0},
            {x = 0, y = station.segmentLength * (nSeg * 0.5 - 2), z = 0},
            {x = 0, y = -station.segmentLength * (nSeg * 0.5 - 2), z = 0}
        },
        {
            {x = 0, y = 0, z = 0},
            {x = 0, y = station.segmentLength * (nSeg * 0.5 - 2), z = 0},
            {x = 0, y = station.segmentLength * (nSeg * 0.5 - 2), z = 0}
        }
    }
end

local function makeUpdateFn(config)
    
    local basicPattern = {config.platformRepeat, config.platformDwlink}
    local basicPatternR = {config.platformDwlink, config.platformRepeat}
    local platformPatterns = function(n)
        return (n > 2) and (func.mapFlatten(func.seq(1, n * 0.5), function(i) return basicPatternR end)) or basicPattern end
    local stationHouse = config.stationHouse
    local staires = config.staires
    
    local function houseEntryConfig(mpt, mvec)
        return {
            model = newModel(stationHouse, coor.rotZ(math.rad(-90)), mpt),
            steetEdegs = coor.applyEdges(mpt, mvec)(
                {
                    {{-20, 0, 0}, {1, 0, 0}},
                    {{-6, 0, 0}, {1, 0, 0}},
                    {{20, 0, 0}, {-1, 0, 0}},
                    {{5, 0, 0}, {-1, 0, 0}},
                }
            ),
            streetType = "station_new_small.lua",
            faces = func.map(
                {
                    {{10, 6, 0}, {-10, 6, 0}, {-10, -6, 0}, {10, -6, 0}}
                }, station.faceMapper(mpt))
        }
    end
    
    local function stairsEntryConfig(mpt, mvec)
        return {
            model = newModel(staires, coor.rotZ(math.rad(-90)), mpt),
            steetEdegs = coor.applyEdges(mpt, mvec)(
                {
                    {{0, -3, 0}, {0, 1, 0}},
                    {{0, 0, 0}, {0, 1, 0}},
                    {{0, 3, 0}, {0, -1, 0}},
                    {{0, 0, 0}, {0, -1, 0}},
                }),
            streetType = "new_medium.lua",
            faces = func.map(
                {
                    {{-8, 0.7, -0.8}, {-8, -0.7, -0.8}, {-13, -0.7, -0.8}, {-13, 0.7, -0.8}},
                    {{13, 0.7, -0.8}, {13, -0.7, -0.8}, {8, -0.7, -0.8}, {8, 0.7, -0.8}},
                }, station.faceMapper(mpt))
        }
    end
    
    local entryList = {
        {houseEntryConfig},
        {stairsEntryConfig},
        {houseEntryConfig, houseEntryConfig, houseEntryConfig},
        {stairsEntryConfig, stairsEntryConfig, stairsEntryConfig},
        {houseEntryConfig, stairsEntryConfig, stairsEntryConfig}
    }
    
    return function(params)
            
            local result = {}
            
            local trackType = ({"standard.lua", "standard.lua", "high_speed.lua", "high_speed.lua"})[params.trackTypeCatenary + 1]
            local catenary = (params.trackTypeCatenary == 1) or (params.trackTypeCatenary == 2)
            local tramTrack = ({"NO", "YES", "ELECTRIC"})[(params.tramTrackType == nil and 0 or params.tramTrackType) + 1]
            local nSeg = platformSegments[params.length + 1]
            local length = nSeg * station.segmentLength
            local nbTracks, nbLevels = table.unpack(nbTracksLevelList[params.nbTracks + 1])
            local height = heightList[params.platformHeight + 1]
            local levels = {}
            local rad = {
                0,
                math.rad(angleList[params.angle2 + 1]) * ((params.mirrored == 1 or params.mirrored == 3) and -1 or 1),
                math.rad(angleList[params.angle3 + 1]) * ((params.mirrored == 2 or params.mirrored == 3) and -1 or 1)
            }
            
            local center = centers(nSeg)[params.topoMode + 1]
            if (params.topoMode == 1) then
                local center3a = coor.apply(center[3], coor.rotZCentered(rad[2], center[2]))
                levels = {
                    {
                        mz = coor.I(),
                        mr = coor.I(),
                        mdr = coor.I(),
                        id = 1
                    },
                    {
                        mz = coor.transZ(-10),
                        mr = coor.rotZ(rad[2]),
                        mdr = coor.rotZCentered(rad[2], center[2]),
                        id = 2
                    },
                    {
                        mz = coor.transZ(-20),
                        mr = coor.rotZ(rad[3] + rad[2]),
                        mdr = coor.mul(coor.trans(coor.sub(center3a, center[3])), coor.rotZCentered(rad[3] + rad[2], center3a)),
                        id = 3
                    }
                }
            elseif (params.topoMode == 2) then
                local dx = 7.5 * nbTracks
                local mdr2 = coor.mul(coor.transX(dx), coor.rotZCentered(rad[2], coor.apply(center[2], coor.transX(0.5 * dx))))
                
                local center3a = coor.applyM(center[3], coor.transX(dx), coor.trans(coor.apply({x = dx, y = 0, z = 0}, coor.rotZ(rad[2]))))
                levels = {
                    {
                        mz = coor.I(),
                        mr = coor.I(),
                        mdr = coor.I(),
                        id = 1
                    },
                    {
                        mz = coor.transZ(-10),
                        mr = coor.rotZ(rad[2]),
                        mdr = coor.mul(coor.transX(dx), coor.rotZCentered(rad[2], coor.apply(center[2], coor.transX(0.5 * dx)))),
                        id = 2
                    },
                    {
                        mz = coor.transZ(-20),
                        mr = coor.rotZ(rad[3]),
                        mdr = coor.mul(coor.trans(coor.sub(center3a, center[3])), coor.rotZCentered(rad[3], coor.apply(center3a, coor.transX(-0.5 * dx)))),
                        id = 3
                    }
                }
            else
                levels = func.seqMap({0, 2}, function(l)
                    return {
                        mz = coor.transZ(0 - l * 10),
                        mr = coor.rotZ(rad[l + 1]),
                        mdr = coor.rotZ(rad[l + 1]),
                        id = l + 1
                    } end)
            end
            
            local entryLocations = func.map2(center, levels, function(o, l) return {coor.mul(coor.trans(coor.apply(o, coor.flipY())), l.mdr), l.mr} end)
            local entryConfig = entryList[params.entryMode + 1]
            if (nSeg < 5) then while #entryConfig > 1 do table.remove(entryConfig) end end
            
            while #levels > nbLevels do table.remove(levels) end
            while #entryConfig > #levels do table.remove(entryConfig) end
            while #entryLocations > #entryConfig do table.remove(entryLocations) end
            
            entryLocations = func.map2(entryConfig, entryLocations, function(f, l) return f(table.unpack(l)) end)
            
            if (params.topoMode == 2 and rad[2] == rad[3] and #entryLocations == 3) then table.remove(entryLocations, 2) end
            
            func.forEach(levels, function(l)
                l.nbTracks = nbTracks
                l.baseX = - 0.5 * station.platformWidth - nbTracks * 0.5 * station.trackWidth
                l.ignoreFst = nbTracks % 4 == 0
                l.ignoreLst = nbTracks % 4 == 0
            end)
            
            local platforms = platformPatterns(nSeg)
            local xOffsets, uOffsets, xuIndex = station.buildCoors(nSeg)(levels, {}, {}, {}, {})
            
            local trueTracks = station.generateTrackGroups(xOffsets, length)
            local mockTracks = station.generateTrackGroups(uOffsets, length)
            
            result.edgeLists = {
                trackEdge.tunnel(catenary, trackType, snapRule)(trueTracks),
                trackEdge.tunnel(false, "zzz_mock.lua", station.noSnap)(mockTracks)
            }
            
            result.models = station.makePlatforms(uOffsets, platforms)
            result.terminalGroups = station.makeTerminals(xuIndex)
            
            station.setHeight(result, height)
            
            result.groundFaces = {}
            result.terrainAlignmentLists = {}
            
            func.forEach(entryLocations, func.bind(addEntry, result, tramTrack))
            
            result.cost = #levels * 60000 + nbTracks * 24000
            result.maintenanceCost = result.cost / 6
            
            return result
    end
end


local mlugstation = {
    makeUpdateFn = function(config)
        return function()
            return {
                type = "RAIL_STATION",
                description = {
                    name = _("Underground / Multi-level Passenger Station"),
                    description = _("An underground / multi-level passenger station")
                },
                availability = config.availability,
                order = config.order,
                soundConfig = config.soundConfig,
                params = params(),
                updateFn = makeUpdateFn(config)
            }
        end
    end
}

return mlugstation
