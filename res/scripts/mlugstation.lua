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
local nbTracksList = {1, 2, 3, 4, 5, 6, 8, 10, 12}

local newModel = function(m, ...)
    return {
        id = m,
        transf = coor.mul(...)
    }
end

local snapRule = function(e) return func.filter(func.seq(0, #e - 1), function(e) return e % 4 == 0 or (e - 3) % 4 == 0 end) end


local function paramsSimplex()
    return {
        {
            key = "nbTracks",
            name = _("Number of tracks"),
            values = func.map(nbTracksList, tostring),
            defaultIndex = 1
        },
        {
            key = "length",
            name = _("Platform length") .. "(m)",
            values = func.map(platformSegments, function(l) return _(tostring(l * station.segmentLength)) end),
            defaultIndex = 2
        },
        paramsutil.makeTrackTypeParam(),
        paramsutil.makeTrackCatenaryParam(),
        {
            key = "centralTracks",
            name = _("Always tracks in the middle"),
            values = {_("Yes"), _("No")},
            defaultIndex = 0
        },
        {
            key = "platformHeight",
            name = _("Depth") .. "(m)",
            values = func.map(heightList, tostring),
            defaultIndex = 1
        },
        paramsutil.makeTramTrackParam1(),
        paramsutil.makeTramTrackParam2(),
        {
            key = "entryMode",
            name = _("Entry Type"),
            values = {_("Mini"), _("Micro")},
            defaultIndex = 1
        },
    }
end


local function paramsDuplex()
    return {
        {
            key = "nbTracks",
            name = _("Number of tracks"),
            values = func.map(nbTracksList, tostring),
            defaultIndex = 1
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
            key = "platformHeight",
            name = _("Depth") .. "(m)",
            values = func.map(heightList, tostring),
            defaultIndex = 1
        },
        {
            key = "angle2",
            name = _("Level -2 Cross angle") .. "(°)",
            values = func.map(angleList, tostring)
        },
        {
            key = "mirrored",
            name = _("Mirrored"),
            values = {_("None"), _("Level -2")}
        },
        paramsutil.makeTramTrackParam1(),
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


local function paramsTriplex()
    return {
        {
            key = "nbTracks",
            name = _("Number of tracks"),
            values = func.map(nbTracksList, tostring),
            defaultIndex = 1
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
            key = "platformHeight",
            name = _("Depth") .. "(m)",
            values = func.map(heightList, tostring),
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
        paramsutil.makeTramTrackParam1(),
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

local function defaultParams(params)
    params.nbTracks = params.nbTracks or 1
    params.nbLevels = params.nbLevels or 1
    params.length = params.length or 2
    params.trackType = params.trackType or 0
    params.catenary = params.catenary or 0
    params.angle2 = params.angle2 or 0
    params.angle3 = params.angle3 or 0
    params.mirrored = params.mirrored or 0
    params.platformHeight = params.platformHeight or 1
    params.tramTrack = params.tramTrack or 0
    params.entryMode = params.entryMode or 1
    params.topoMode = params.topoMode or 0
    params.centralTracks = params.centralTracks or 0
end

local function defaultParamsSimplex(params)
    params.nbLevels = 1
    params.topoMode = 0
    
    defaultParams(params)
end


local function defaultParamsDuplex(params)
    params.nbLevels = 2
    params.centralTracks = 0
    params.trackType = ({0, 0, 1, 1})[params.trackTypeCatenary + 1]
    params.catenary = ({0, 1, 1, 0})[params.trackTypeCatenary + 1]
    defaultParams(params)
end


local function defaultParamsTriplex(params)
    params.nbLevels = 3
    params.centralTracks = 0
    params.trackType = ({0, 0, 1, 1})[params.trackTypeCatenary + 1]
    params.catenary = ({0, 1, 1, 0})[params.trackTypeCatenary + 1]
    defaultParams(params)
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
            coor.xyz(0, 0, 0),
            coor.xyz(0, station.segmentLength * (nSeg * 0.5 - 2), 0),
            coor.xyz(0, -station.segmentLength * (nSeg * 0.5 - 2), 0)
        },
        {
            coor.xyz(0,0, 0),
            coor.xyz(0,station.segmentLength * (nSeg * 0.5 - 2), 0),
            coor.xyz(0,-station.segmentLength * (nSeg * 0.5 - 2), 0)
        },
        {
            coor.xyz(0, 0, 0),
            coor.xyz(0, station.segmentLength * (nSeg * 0.5 - 2), 0),
            coor.xyz(0, station.segmentLength * (nSeg * 0.5 - 2), 0)
        }
    }
end

local function makeUpdateFn(config, paramsChecker)
    
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
            
            paramsChecker(params)
            
            local result = {}
            
            local trackType = ({"standard.lua", "high_speed.lua"})[params.trackType + 1]
            local catenary = params.catenary == 1
            local tramTrack = ({"NO", "YES", "ELECTRIC"})[params.tramTrack + 1]
            local nSeg = platformSegments[params.length + 1]
            local length = nSeg * station.segmentLength
            local nbTracks = nbTracksList[params.nbTracks + 1]
            local nbLevels = params.nbLevels
            local height = heightList[params.platformHeight + 1]
            local levels = {}
            local rad = {
                0,
                math.rad(angleList[params.angle2 + 1]) * ((params.mirrored == 1 or params.mirrored == 3) and -1 or 1),
                math.rad(angleList[params.angle3 + 1]) * ((params.mirrored == 2 or params.mirrored == 3) and -1 or 1)
            }
            
            local preXOffset, preUOffsets = station.preBuild(nbTracks, 0, ({false, true})[params.centralTracks + 1], ({false, true})[params.centralTracks + 1])
            local center = centers(nSeg)[params.topoMode + 1]
            local baseX = -(preUOffsets[math.ceil((1 + #preUOffsets) * 0.5)] + preUOffsets[math.floor((1 + #preUOffsets) * 0.5)]) * 0.5
            local function newLevel(info)
                return {
                    mz = info.mz,
                    mr = info.mr,
                    mdr = info.mdr,
                    id = info.id,
                    nbTracks = nbTracks,
                    baseX = baseX,
                    ignoreFst = ({false, true})[params.centralTracks + 1],
                    ignoreLst = ({false, true})[params.centralTracks + 1]
                }
            end
            
            if (params.topoMode == 1) then
                local function makeLevel(lev)
                    if (lev == 1) then
                        return { newLevel({mz = coor.I(), mr = coor.I(), mdr = coor.I(), id = lev}) }
                    else
                        local precedentLevels = makeLevel(lev - 1)
                        local lastLevel = precedentLevels[#precedentLevels]
                        local ncenter = center[lev] .. lastLevel.mdr
                        return func.concat(
                            precedentLevels,
                            {
                                newLevel({
                                    mz = lastLevel.mz * coor.transZ(-10),
                                    mr = lastLevel.mr * coor.rotZ(rad[lev]),
                                    mdr = coor.trans(ncenter - center[lev]) * coor.centered(coor.rotZ, rad[lev] + rad[lev - 1], ncenter),
                                    id = lev
                                })
                            }
                    )
                    end
                end
                levels = makeLevel(3)
            elseif (params.topoMode == 2) then
                local dx = preUOffsets[#preUOffsets] - preUOffsets[1] + 15
                local function makeLevel(lev)
                    if (lev == 1) then
                        return { newLevel({mz = coor.I(), mr = coor.I(), mdr = coor.I(), id = lev}) }
                    else
                        local precedentLevels = makeLevel(lev - 1)
                        local lastLevel = precedentLevels[#precedentLevels]
                        local ncenter = center[lev] .. coor.transX(dx * 0.5) * lastLevel.mdr
                        return func.concat(
                            precedentLevels,
                            {
                                newLevel({
                                    mz = lastLevel.mz * coor.transZ(-10),
                                    mr = lastLevel.mr * coor.rotZ(rad[lev]),
                                    mdr = coor.transX(dx) * lastLevel.mdr * coor.centered(coor.rotZ, rad[lev], ncenter),
                                    id = lev
                                })
                            }
                    )
                    end
                end
                levels = makeLevel(3)
            else
                levels = func.seqMap({0, 2}, function(l)
                    return newLevel({
                        mz = coor.transZ(0 - l * 10),
                        mr = coor.rotZ(rad[l + 1]),
                        mdr = coor.rotZ(rad[l + 1]),
                        id = l + 1
                    }) end)
            end
            
            local entryLocations = func.map2(center, levels, function(o, l) return {coor.trans(o..coor.flipY()) * l.mdr, l.mr} end)
            local entryConfig = entryList[params.entryMode + 1]
            if (nSeg < 5) then while #entryConfig > 1 do table.remove(entryConfig) end end
            
            while #levels > nbLevels do table.remove(levels) end
            while #entryConfig > #levels do table.remove(entryConfig) end
            while #entryLocations > #entryConfig do table.remove(entryLocations) end
            
            entryLocations = func.map2(entryConfig, entryLocations, function(f, l) return f(table.unpack(l)) end)
            
            if (params.topoMode == 2 and rad[2] == rad[3] and #entryLocations == 3) then table.remove(entryLocations, 2) end
            
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
    end,
    
    makeUpdateFnSimplex = function(config)
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
                params = paramsSimplex(),
                updateFn = makeUpdateFn(config, defaultParamsSimplex)
            }
        end
    end,
    
    makeUpdateFnDuplex = function(config)
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
                params = paramsDuplex(),
                updateFn = makeUpdateFn(config, defaultParamsDuplex)
            }
        end
    end,
    
    makeUpdateFnTriplex = function(config)
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
                params = paramsTriplex(),
                updateFn = makeUpdateFn(config, defaultParamsTriplex)
            }
        end
    end
}

return mlugstation
