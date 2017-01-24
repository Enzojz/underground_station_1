local laneutil = require "laneutil"
local paramsutil = require "paramsutil"
local func = require "func"
local coor = require "coor"
local trackEdge = require "trackedge"
local dump = require "datadumper"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {-10, -15, -20}
local segmentLength = 20
local platformWidth = 5
local trackWidth = 5
local angleList = {0, 15, 30, 45, 60, 75, 90}
local nbTracksLevelList = {{2, 1}, {4, 1}, {2, 2}, {4, 2}, {2, 3}, {4, 3}}
local nbTracksPlatform = {2, 4, 6, 8}

local newModel = function(m, ...)
    dump.dump({...})
    return {
        id = m,
        transf = coor.mul(...)
    }
end

local makeTerminals = function(terminals, side, track)
    return {
        terminals = func.map(terminals, function(t) return {t, side} end),
        vehicleNodeOverride = track * 4 - 2
    }
end

local function generateTrackGroups(xOffsets, xParity, length)
    local halfLength = length * 0.5
    return func.flatten(
        func.map2(xOffsets, xParity,
            function(xOffset, m)
                return coor.applyEdges(coor.mul(m, xOffset.mpt), coor.mul(m, xOffset.mvec))(
                    {
                        {{0, -halfLength, 0}, {0, halfLength, 0}},
                        {{0, 0, 0}, {0, halfLength, 0}},
                        {{0, 0, 0}, {0, halfLength, 0}},
                        {{0, halfLength, 0}, {0, halfLength, 0}},
                    })
            end
))
end

local function buildCoors(nSeg)
    local groupWidth = trackWidth + platformWidth
    
    local function buildUIndex(uOffset, ...) return {func.seq(uOffset * nSeg, (uOffset + 1) * nSeg - 1), {...}} end
    
    local function buildGroup(nbTracks, level, baseX, xOffsets, uOffsets, xuIndex, xParity)
        local project = function(x) return func.map(x, function(offset) return {mpt = coor.mul(coor.transX(offset), level.mdr, level.mz), mvec = level.mr} end) end
        if (nbTracks == 0) then
            return
                xOffsets, uOffsets, xuIndex, xParity
        elseif (nbTracks == 1) then
            return buildGroup(nbTracks - 1, level, baseX + groupWidth - 0.5 * trackWidth,
                func.concat(xOffsets, project({baseX + platformWidth})),
                func.concat(uOffsets, project({baseX + platformWidth - trackWidth})),
                func.concat(xuIndex, {buildUIndex(#uOffsets, {1, #xOffsets + 1})}),
                func.concat(xParity, {coor.flipY()})
        )
        else
            return buildGroup(nbTracks - 2, level, baseX + groupWidth + trackWidth,
                func.concat(xOffsets, project({baseX, baseX + groupWidth})),
                func.concat(uOffsets, project({baseX + 0.5 * groupWidth})),
                func.concat(xuIndex, {buildUIndex(#uOffsets, {0, #xOffsets + 1}, {1, #xOffsets + 2})}),
                func.concat(xParity, {coor.I(), coor.flipY()})
        )
        end
    end
    
    local function build(trackGroups, baseX, ...)
        
        if (#trackGroups == 1) then
            local nbTracks, level = table.unpack(trackGroups[1])
            return buildGroup(nbTracks, level, baseX, ...)
        else
            return build(func.range(trackGroups, 2, #trackGroups), baseX, build({trackGroups[1]}, baseX, ...))
        end
    end
    
    return build
end

local snapRule = function(e) return func.filter(func.seq(0, #e - 1), function(e) return e % 4 == 0 or (e - 3) % 4 == 0 end) end
local noSnap = function(e) return {} end

local function setHeight(result, height)
    local mpt = coor.transZ(height)
    local mvec = coor.I()
    
    local mapEdgeList = function(edgeList)
        edgeList.edges = func.map(edgeList.edges, coor.applyEdge(mpt, mvec))
        return edgeList
    end
    
    result.edgeLists = func.map(result.edgeLists, mapEdgeList)
    
    local mapModel = function(model)
        model.transf = coor.mul(model.transf, mpt)
        return model
    end
    
    result.models = func.map(result.models, mapModel)
end

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
            values = func.map(platformSegments, function(l) return _(tostring(l * segmentLength)) end),
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

local faceMapper = function(m)
    return function(face)
        return func.map(face, function(pt) return func.pipe(pt, coor.tuple2Vec, func.bind(coor.apply, nil, m), coor.vec2Tuple) end)
    end
end

local function centers(nSeg)
    return {
        {
            {x = 0, y = 0, z = 0},
            {x = 0, y = segmentLength * (nSeg * 0.5 - 2), z = 0},
            {x = 0, y = -segmentLength * (nSeg * 0.5 - 2), z = 0}
        },
        {
            {x = 0, y = 0, z = 0},
            {x = 0, y = segmentLength * (nSeg * 0.5 - 2), z = 0},
            {x = 0, y = -segmentLength * (nSeg * 0.5 - 2), z = 0}
        },
        {
            {x = 0, y = 0, z = 0},
            {x = 0, y = segmentLength * (nSeg * 0.5 - 2), z = 0},
            {x = 0, y = segmentLength * (nSeg * 0.5 - 2), z = 0}
        }
    }
end

local function updateFn(config)
    
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
                }, faceMapper(mpt))
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
                }, faceMapper(mpt))
        }
    end
    
    local entryList = {
        {houseEntryConfig},
        {stairsEntryConfig},
        {houseEntryConfig, houseEntryConfig, houseEntryConfig},
        {stairsEntryConfig, stairsEntryConfig, stairsEntryConfig},
        {houseEntryConfig, stairsEntryConfig, stairsEntryConfig}
    }
    
    return
        function(params)
            
            local result = {}
            
            local trackType = ({"standard.lua", "standard.lua", "high_speed.lua", "high_speed.lua"})[params.trackTypeCatenary + 1]
            local catenary = (params.trackTypeCatenary == 1) or (params.trackTypeCatenary == 2)
            local tramTrack = ({"NO", "YES", "ELECTRIC"})[(params.tramTrackType == nil and 0 or params.tramTrackType) + 1]
            local nSeg = platformSegments[params.length + 1]
            local length = nSeg * segmentLength
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
                        mdr = coor.I()
                    },
                    {
                        mz = coor.transZ(-10),
                        mr = coor.rotZ(rad[2]),
                        mdr = coor.rotZCentered(rad[2], center[2])
                    },
                    {
                        mz = coor.transZ(-20),
                        mr = coor.rotZ(rad[3]),
                        mdr = coor.mul(coor.trans(coor.sub(center3a, center[3])), coor.rotZCentered(rad[3], center3a))
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
                        mdr = coor.I()
                    },
                    {
                        mz = coor.transZ(-10),
                        mr = coor.rotZ(rad[2]),
                        mdr = coor.mul(coor.transX(dx), coor.rotZCentered(rad[2], coor.apply(center[2], coor.transX(0.5 * dx))))
                    },
                    {
                        mz = coor.transZ(-20),
                        mr = coor.rotZ(rad[3]),
                        mdr = coor.mul(coor.trans(coor.sub(center3a, center[3])), coor.rotZCentered(rad[3], coor.apply(center3a, coor.transX(-0.5 * dx))))
                    }
                }
            else
                levels = func.seqMap({0, 2}, function(l)
                    return {
                        mz = coor.transZ(0 - l * 10),
                        mr = coor.rotZ(rad[l + 1]),
                        mdr = coor.rotZ(rad[l + 1])
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
            
            local totalWidth = nbTracks * (trackWidth + 0.5 * platformWidth)
            local platforms = platformPatterns(nSeg)
            local xOffsets, uOffsets, xuIndex, xParity =
                buildCoors(nSeg)(func.map(levels, function(l) return {nbTracks, l} end), 0.5 * (-totalWidth + trackWidth), {}, {}, {}, {})
            
            local trueTracks = generateTrackGroups(xOffsets, xParity, length)
            local mockTracks = generateTrackGroups(uOffsets, func.seqValue(#uOffsets, coor.I()), length)
            
            result.edgeLists = {
                trackEdge.tunnel(catenary, trackType, snapRule)(trueTracks),
                trackEdge.tunnel(false, "zzz_mock.lua", noSnap)(mockTracks)
            }
            
            result.models =
                func.mapFlatten(uOffsets,
                    function(uOffset)
                        return func.seqMap({1, #platforms}, function(i) return newModel(platforms[i], coor.transY(i * 20 - 0.5 * (segmentLength + length)), uOffset.mpt) end
                    )
                    end)
            
            result.terminalGroups = func.mapFlatten(xuIndex, function(v)
                local u, xIndices = table.unpack(v)
                return func.map(xIndices, function(x) return makeTerminals(u, table.unpack(x)) end
            )
            end)
            
            setHeight(result, height)
            
            result.groundFaces = {}
            result.terrainAlignmentLists = {}
            
            func.forEach(entryLocations, func.bind(addEntry, result, tramTrack))
            
            result.cost = #levels * 60000 + nbTracks * 24000
            result.maintenanceCost = result.cost / 6
            
            return result
        end
end


local mlugstation = {
    dataCallback = function(config)
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
                updateFn = updateFn(config)
            }
        end
    end
}

return mlugstation
