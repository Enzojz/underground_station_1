local func = require "func"
local coor = require "coor"
local trackEdge = require "trackedge"

local newModel = function(m, ...)
    return {
        id = m,
        transf = coor.mul(...)
    }
end


local stationlib = {
    platformWidth = 5,
    trackWidth = 5,
    segmentLength = 20
}


stationlib.generateTrackGroups = function(xOffsets, xParity, length)
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

stationlib.buildCoors = function(nSeg)
    local groupWidth = stationlib.trackWidth + stationlib.platformWidth
    
    local function buildUIndex(uOffset, ...) return {func.seq(uOffset * nSeg, (uOffset + 1) * nSeg - 1), {...}} end
    
    local function buildGroup(nbTracks, level, baseX, xOffsets, uOffsets, xuIndex, xParity)
        local project = function(x) return func.map(x, function(offset) return {mpt = coor.mul(coor.transX(offset), level.mdr, level.mz), mvec = level.mr} end) end
        if (nbTracks == 0) then
            return xOffsets, uOffsets, xuIndex, xParity
        elseif (nbTracks == 1) then
            return buildGroup(nbTracks - 1, level, baseX + groupWidth - 0.5 * trackWidth,
                func.concat(xOffsets, project({baseX + stationlib.platformWidth})),
                func.concat(uOffsets, project({baseX + stationlib.platformWidth - stationlib.trackWidth})),
                func.concat(xuIndex, {buildUIndex(#uOffsets, {1, #xOffsets + 1})}),
                func.concat(xParity, {coor.flipY()})
        )
        else
            return buildGroup(nbTracks - 2, level, baseX + groupWidth + stationlib.trackWidth,
                func.concat(xOffsets, project({baseX, baseX + groupWidth})),
                func.concat(uOffsets, project({baseX + 0.5 * groupWidth})),
                func.concat(xuIndex, {buildUIndex(#uOffsets, {0, #xOffsets + 1}, {1, #xOffsets + 2})}),
                func.concat(xParity, {coor.I(), coor.flipY()})
        )
        end
    end
    
    local function build(trackGroups, ...)
        if (#trackGroups == 1) then
            local group = table.unpack(trackGroups)
            return buildGroup(group.nbTracks, group, group.baseX, ...)
        else
            return build(func.range(trackGroups, 2, #trackGroups), build({trackGroups[1]}, ...))
        end
    end
    return build
end

stationlib.noSnap = function(e) return {} end

stationlib.makePlatforms = function(uOffsets, platforms)
    local length = #platforms * stationlib.segmentLength
    return func.mapFlatten(uOffsets,
        function(uOffset)
            return func.map2(func.seq(1, #platforms), platforms, function(i, p)
                return newModel(p, coor.transY(i * stationlib.segmentLength - 0.5 * (stationlib.segmentLength + length)), uOffset.mpt) end
        )
        end)
end

stationlib.makeTerminals = function(xuIndex)
    return func.mapFlatten(xuIndex, function(xu)
        local terminals, xIndices = table.unpack(xu)
        return func.map(xIndices, function(x)
            local side, track = table.unpack(x)
            return {
                terminals = func.map(terminals, function(t) return {t, side} end),
                vehicleNodeOverride = track * 4 - 2
            }
        end
    )
    end)
end

stationlib.setHeight = function(result, height)
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

stationlib.faceMapper = function(m)
    return function(face)
        return func.map(face, function(pt) return func.pipe(pt, coor.tuple2Vec, func.bind(coor.apply, nil, m), coor.vec2Tuple) end)
    end
end


return stationlib
