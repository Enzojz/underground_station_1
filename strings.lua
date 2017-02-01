local descEN = [[An underground station with one/multi-level possibilty, it can be used to configure a Spanish solution or Cross Station.
Features:
* Visible platforms
* From 1 to 12 tracks for each level
* From 40m to 480m platform lengths
* 1, 2, 3 levels and assured interchange channels between -1 and -2 and between -2 and -3 layers
* Cross station options
* Mini metro like station entry with various modes
* Multiple layout choices
* Extensible MOD (You can make your own underground and multi-level stations with this MOD)

To be implemented:
* Real stairs

---------------
Changelog
1.5
* Seperate station of different levels into different menu items
* Central Track option for simplex station
* More tracks (up to 12 tracks for each level)

1.4
* Central tracks for 2 tracks configuration
* Corrected algorithm for triangle layout
* Stabilty may be improved

1.3
* Fixed issue that no catchment area on 40m platforms brought in 1.2.(need station upgrade on saved games)
* Replaced 500m platform which never worked with that of 480m.
* Added Tram Track Type option.

1.2
* The issue of [i]reproducible[/i] crash on 2-layer and 3-layer station is likely fixed. (need station upgrade on saved games)
* Added tram track on mini entries.

1.1
* Formal release
* Mock tracks are hidden (need station upgrade on saved games)
* Bumpers at the end of platforms are removed (need station upgrade on saved games)
* Selection of Star, Triangle, Side by Side layouts

0.9
Pre-release beta
--------------- 
* Planned projects 
- Elevated station 
- Curved station 
- Overground / elevated Crossing station 
]]

local descFR = [[Une gare souterrain avec possibility d'avoir plusieurs niveaux et platformes croisée.
Caractéristiques:
* Platformes visibles
* De 1 jusqu'à 12 voies pour chaque niveaux
* Longueur de platformes de 40m jusqu'à 480m
* 1, 2 ou 3 niveaux avec correspondence de platforme assuré entre niveaux -1,-2 et -2,-3
* Option gare en croix
* Mini entrée comme métro avec plusieur configurations
* Plusieurs disposition de voie disponibles
* Extensible pour MOD

À implémenter
* Escalier vrai sur plateformes

---------------
Changelog
1.5
* Seperation des gares de niveaux différents dans le menu
* Option pour voie centralisé pour la gare simplex
* Plus de voie (jusqu'à 12 voies pour chaques niveau)

1.4
* Voie centrale pour configuration de 2 voies.
* Correction d'algorithme pour la configuration triangle
* Stabilité est peut-être amélioré. 

1.3
* Correction de problem relié aux platforme de 40m et de 500m dans version 1.2 (utilisez "Agrandir" pour faire la mise à jour si vous avez sauvegarde de jeux)
* Platforme de 500m qui ne marche jamais est remplacé par celui de 480m
* Option type de voie de tram ajouté

1.2
* Le plantage avec gare de 2 niveaux et 3 niveaux semble être corrigé (utilisez "Agrandir" pour faire la mise à jour si vous avez sauvegarde de jeux)
*  Ajoute de voie de tram sur la sortie mini

1.1
* Annoncement formel
* Fausse voies sont cachées (utlisez "Agrandir" pour faire la mise à jour si vous avez version 0.9)
* Tampon à la fin de plateformes sont supprimés (utlisez "Agrandir" pour faire la mise à jour si vous avez version 0.9)
* Disposition de voie: étoile, triangle, côte à côte

0.9
Pre-release beta
]]

descZH = [[一种可以配置多层交错的地下车站，可以用来建设交叉车站和西班牙站台。
特点：
* 可以看到站台
* 每层1至或12条轨道
* 站台长度从40米到480米
* 多至三层
* 交叉车站选项
* 可以选择楼梯或者站房入口
* 地下二层和地下一层，以及地下三层和地下二层的站台之间互相连通
* 多种站台布局可选
* 可扩展

---------------
Changelog
1.5
* 将不同层数的车站分入了菜单中不同的选项中
* 单层车站增加了中央股道的选项
* 更多的股道(每层最多至12条)

1.4
* 两股道配置中将股道移至了中央
* 修正了三角形布局的算法
* 可能提高了稳定性

1.3
* 修正了1.2版本中带来的40米站台无效的问题，对于已经保存的游戏，需要使用车站升级功能更新其配置修正错误。
* 用480米站台替换了500米站台
* 增加了有轨电车轨道类型的选项

1.2
* 因为使用地下2层或者3层车站到导致的游戏退出问题似乎已经被解决，对于已经保存的游戏，需要使用车站升级功能更新其配置修正错误。
* 增加楼梯入口处的电车轨道

1.1
* 正式发布
* 隐藏了占位轨道
* 去除了站台末端的缓冲台
* 增加了站台布局：星形、三角形、边靠边

0.9
Beta测试
]]

function data()
    return {
        en = {
            ["name"] = "Underground / Multi-Level Train Stations",
            ["desc"] = descEN
        },
        fr = {
            ["name"] = "Gare souterrain avec plusieurs niveaux",
            ["desc"] = descFR,
            ["Number of tracks"] = "Nombre de voies",
            ["Track Type & Catenary"] = "Type de voie & Caténaire",
            ["Elec."] = "Élec.",
            ["Hi-Speed"] = "GV",
            ["Elec.Hi-Speed"] = "GV.Élec.",
            ["Level -2 Cross angle"] = "Angle de croisement de n.-2",
            ["Level -3 Cross angle"] = "Angle de croisement de n.-3",
            ["Mirrored"] = "En miroire",
            ["Level"] = "Niveau",
            ["Levels"] = "Niveaux",
            ["None"] = "Aucun",
            ["Level -2"] = "n.-2",
            ["Level -3"] = "n.-3",
            ["Levels -2 & -3"] = "n.-2 & -3",
            ["Depth"] = "Profondeur",
            ["Layout"] = "Disposition de voie",
            ["Star"] = "Étoile",
            ["Triangle"] = "Triangle",
            ["Side by Side"] = "Côte à côte",
            ["Entry Type"] = "Disposition des entrées",
            ["Mixed"] = "Mélangé",
        },
        zh_CN = {
            ["name"] = "多层地下车站",
            ["desc"] = descZH,
            ["Number of tracks"] = "轨道数量",
            ["Track Type & Catenary"] = "轨道类型和电气化",
            ["Platform length"] = "站台长度",
            ["Normal"] = "普通",
            ["Elec."] = "电化",
            ["Hi-Speed"] = "无电高速",
            ["Elec.Hi-Speed"] = "电化高速",
            ["Level -2 Cross angle"] = "地下2层交错角",
            ["Level -3 Cross angle"] = "地下3层交错角",
            ["Mirrored"] = "镜像",
            ["Level"] = "层",
            ["Levels"] = "层数",
            ["None"] = "无",
            ["Level -2"] = "-2层",
            ["Level -3"] = "-3层",
            ["Levels -2 & -3"] = "-2层与-3层",
            ["Depth"] = "深度",
            ["Layout"] = "站台布局",
            ["Star"] = "星形",
            ["Triangle"] = "三角",
            ["Side by Side"] = "边靠边",
            ["Entry Type"] = "入口布局",
            ["Mixed"] = "混合",
            ["1 Mini"] = "单站房",
            ["1 Micro"] = "单楼梯",
            ["Mini"] = "站房",
            ["Micro"] = "楼梯"
        },
    }
end
