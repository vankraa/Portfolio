module ZomZoms exposing (..)
import Browser
import Browser.Events as BEvents exposing (onClick)
import Browser.Navigation exposing (Key(..))
import GraphicSVG exposing (..)
import GraphicSVG.App exposing (..)
import Url
import Random
import Http
import Html
import Html.Attributes as Att
import Html.Events as HEvents
import Json.Encode as Encode
import Json.Decode as Decode
import Time
import Tuple exposing (..)
import String


rootUrl = "https://mac1xa3.ca/e/vankraa/"

type Msg = Tick Float GetKeyState       --default graphicsSVG message called once every browser refresh
    | Tock Time.Posix       --Message called by time subscription to start the clock every round
    | MakeRequest Browser.UrlRequest    --called on any browser request. Used to save progress
    | UrlChange Url.Url     --called on any browser url change. Also used to save progress
    | Play      --Begin next round
    | StatsButton   --move to the statistics/highscores screen
    | ShopButton    --move to the shop
    | Death       --call to end game and reset stats
    | Direction (Float, Float)  --called on any mouse movement to change the direction of the player
    | NewZombie Zombie      --generates a zombie
    | Shoot Time.Posix      --generates 1+ bullet(s)
    | MouseDown String      --used to repeat the shoot call and to change button colours
    | MouseUp       --used to end the repeating shoot call and to change button colours
    | SpeedUp       --each message associated to each stat 
    | ArmorUp
    | MuzzleVUp
    | DamageUp
    | FireRateUp
    | SpreadUp
    | PenetrationUp
    | HealthRegenUp
    | Joke Int      --list of random poor jokes is displayed when a user cant afford an upgrade
    | Name String       --name, pass and pass2 are just called to display information entered into a field in the login form
    | Password String
    | Password2 String
    | GotResponse (Result Http.Error String)    --receives Http strings from the server
    | Save      --save stats
    | JsonUser (Result Http.Error UserInfo)     --receives and assigns the user's cash, killcount and number of days survived
    | JsonStats (Result Http.Error Stats)       --receives and assigns the user's stat progress
    | Signup -- Button to trigger addPerson
    | Login     --assigns user stats and progress upon successful login
    | Logout    --ends authentication session
    | Attempt   --sends username and password to the server to authenticate a session
    | HighscoreList (Result Http.Error Highscores)      --calls the server to sort the highscore list and send it here
    | NoOp      --empty message

type Phase      --game state
    = Title
    | Start
    | Shop
    | Scoreboard
    | Died

type alias Zombie =     --x and y are position, dir is direction
    { speed : Float
    , size : Float
    , x : Float
    , y : Float
    , hp : Float
    , maxHp : Float
    , dmg : Float
    , colour : Color
    , dir : Float
    , value : Float
    , isHit : Float
    }

type alias Army =
    List Zombie


type alias Bullet = 
    { x : Float
    , y : Float
    , dir : Float
    , size : Float
    , dmg : Float
    , speed : Float
    , penetration : Int
    , hitList : List Int
    }

type alias Gun =
    List Bullet

type alias Upgrade =
    { value : Float
    , progress : Float
    , cost : Int
    , click : Bool
    }

type alias Stats =
    { speed : Upgrade
    , armor : Upgrade
    , muzzleV : Upgrade
    , damage : Upgrade
    , fireRate : Upgrade
    , spread : Upgrade
    , penetration : Upgrade
    , healthRegen : Upgrade
    }

type alias UserInfo =
    { day : Int
    , cash : Int
    , score : Int
    }

type alias Highscores =
    { n1 : String
 , s1 : Int, d1 : Int
    , n2 : String, s2 : Int, d2 : Int
    , n3 : String, s3 : Int, d3 : Int
    , n4 : String, s4 : Int, d4 : Int
    , n5 : String, s5 : Int, d5 : Int
    , n6 : String, s6 : Int, d6 : Int
    , n7 : String, s7 : Int, d7 : Int
    , n8 : String, s8 : Int, d8 : Int
    , n9 : String, s9 : Int, d9 : Int
    , n10 : String, s10 : Int, d10 : Int
    }

type alias Model = 
    { name : String
    , pass : String
    , pass2 : String
    , com : String
    , phase : Phase
    , timer : Int
    , day : Int
    , pPress : Bool
    , sPress : Bool
    , qPress : Bool
    , score : Int
    , hScores : Highscores
    , gun : Gun
    , army : Army
    , spawn : Bool
    , cash : Int
    , poorBoy : Float
    , heroX : Float
    , heroY : Float
    , heroDir : Float
    , upgrades : Stats
    , userInfo : UserInfo
    , heroSpeed : Float
    , heroHp : Float
    , heroMaxHp : Float
    , healthRegen : Float
    , damage : Float
    , reload : Float
    , fireRate : Float
    , hold : Bool
    , penetration : Int
    , muzzleV : Float
    , spread : Int
    , joke : (String, String)
    } 

init : () -> Url.Url -> Key -> ( Model, Cmd Msg )
init flags url key = 
    let model = { name = ""
                , pass = ""
                , pass2 = ""
                , com = ""
                , phase = Start
                , timer = 0
                , day = 0
                , pPress = False
                , sPress = False
                , qPress = False
                , score = 0
                , hScores = hScoreList
                , gun = []
                , army = []
                , spawn = False
                , cash = 20
                , poorBoy = 3
                , heroX = 0
                , heroY = 0
                , heroSpeed = 3
                , heroDir = 0
                , heroHp = 100
                , heroMaxHp = 100
                , userInfo = { day = 0 , cash = 20 , score = 0 }
                , upgrades = statsUpgrades
                , healthRegen = 0
                , damage = 5
                , reload = 0
                , fireRate = 1/3
                , hold = False
                , penetration = 1
                , muzzleV = 10
                , spread = 1
                , joke = ("","")
                }    
    in ( model , Cmd.none )


--reset stats upon death

youDied : Model -> Model
youDied model = { model | timer = 0
                , phase = Died
                , day = 0
                , pPress = False
                , sPress = False
                , qPress = False
                , score = 0
                , hScores = hScoreList
                , gun = []
                , army = []
                , spawn = False
                , cash = 20
                , poorBoy = 3
                , heroX = 0
                , heroY = 0
                , heroSpeed = 3
                , heroDir = 0
                , heroHp = 100
                , heroMaxHp = 100
                , userInfo = { day = 0 , cash = 20 , score = 0 }
                , upgrades = statsUpgrades
                , healthRegen = 0
                , damage = 5
                , reload = 0
                , fireRate = 1/3
                , hold = False
                , penetration = 1
                , muzzleV = 10
                , spread = 1
                }

--Stat upgrade initializers

speedStat = { value = 3, progress = 0, cost = 20, click = False }

armorStat = { value = 100, progress = 0, cost = 20, click = False }

muzzleVStat = { value = 10, progress = 0, cost = 20, click = False }

damageStat = { value = 5, progress = 0, cost = 20, click = False }

fireRateStat = { value = 1/3, progress = 0, cost = 20, click = False }

spreadStat = { value = 1, progress = 0, cost = 20, click = False }

penetrationStat = { value = 1, progress = 0, cost = 20, click = False }

healthRegenStat = { value = 0, progress = 0, cost = 20, click = False }

statsUpgrades = { speed = speedStat
                , armor = armorStat
                , muzzleV = muzzleVStat
                , damage = damageStat 
                , fireRate = fireRateStat
                , spread = spreadStat
                , penetration = penetrationStat
                , healthRegen = healthRegenStat
                }

--highscore list init

hScoreList =
    { n1 = "", s1 = 0, d1 = 0
    , n2 = "", s2 = 0, d2 = 0
    , n3 = "", s3 = 0, d3 = 0
    , n4 = "", s4 = 0, d4 = 0
    , n5 = "", s5 = 0, d5 = 0
    , n6 = "", s6 = 0, d6 = 0
    , n7 = "", s7 = 0, d7 = 0
    , n8 = "", s8 = 0, d8 = 0
    , n9 = "", s9 = 0, d9 = 0
    , n10 = "", s10 = 0, d10 = 0
    }

--Server communication

encodeUser : String -> String -> Encode.Value   --sends name and password to server for authentication
encodeUser name pass =
    Encode.object
        [ ( "name" , Encode.string name )
        , ( "pass" , Encode.string pass )
        ]

addUser : String -> String -> Cmd Msg       --sends name and password to server for authentication and registers the user to be saved in the database
addUser name pass =
    Http.post
        { url = rootUrl ++ "zomdataapp/add_user/"
        , body = Http.jsonBody <| encodeUser name pass
        , expect = Http.expectString GotResponse
        }

attemptLogin : String -> String -> Cmd Msg      --check to see if the username and password are valid
attemptLogin name pass =
    Http.post
        { url = rootUrl ++ "zomdataapp/attempt_login/"
        , body = Http.jsonBody <| encodeUser name pass
        , expect = Http.expectString GotResponse
        }

logOut : Cmd Msg        --ends authentication session
logOut = 
    Http.get
        { url = rootUrl ++ "zomdataapp/log_out/"
        , expect = Http.expectString GotResponse
        } 

encodeScore : UserInfo -> Encode.Value      --encodes the user progress to be sent to the server
encodeScore ui =
    Encode.object
        [ ( "score" , Encode.int ui.score )
        , ( "day" , Encode.int ui.day )
        , ( "cash" , Encode.int ui.cash )
        ]

encodeOneStat : Upgrade -> Encode.Value     --encodes one stat in order to collect the individual information into one json request
encodeOneStat u = 
    Encode.object
        [ ( "value" , Encode.float u.value )
        , ( "progress" , Encode.float u.progress )
        , ( "cost" , Encode.int u.cost )
        ]

encodeStats : Stats -> Encode.Value     --encodes each encoded stat to be sent as a json object to the server for saving progress
encodeStats s = 
    Encode.object
        [ ( "speed" , encodeOneStat s.speed )
        , ( "armor" , encodeOneStat s.armor )
        , ( "damage" , encodeOneStat s.damage )
        , ( "muzzleV" , encodeOneStat s.muzzleV )
        , ( "fireRate" , encodeOneStat s.fireRate )
        , ( "spread" , encodeOneStat s.spread )
        , ( "penetration" , encodeOneStat s.penetration )
        , ( "healthRegen" , encodeOneStat s.healthRegen )
        ]

saveScore : UserInfo -> Cmd Msg     --post to send the player's progress to the server
saveScore ui =
    Http.post
        { url = rootUrl ++ "zomdataapp/save_progress/"
        , body = Http.jsonBody <| encodeScore ui
        , expect = Http.expectString GotResponse
        }

saveStats : Stats -> Cmd Msg        --post to send the user's current stats to the server
saveStats stats =
    Http.post
        { url = rootUrl ++ "zomdataapp/save_stats/"
        , body = Http.jsonBody <| encodeStats stats
        , expect = Http.expectString GotResponse
        }

getStats : Stats -> String -> String -> Cmd Msg     --get request returns stats if the user is authenticated and nothing if they are not
getStats stats name pass =
    Http.get
        { url = rootUrl ++ "zomdataapp/get_stats/"
        , expect = Http.expectJson JsonStats ( statsDecoder stats )
        }

getScore : UserInfo -> String -> String -> Cmd Msg      --get request returns score/cash/day# if the user is authenticated and nothing if they are not
getScore ui name pass =
    Http.get
        { url = rootUrl ++ "zomdataapp/get_score/"
        , expect = Http.expectJson JsonUser ( userDecoder ui )
        }

getHighscore : Highscores -> Cmd Msg        --get request pulls the highscores from the server
getHighscore hs = 
    Http.get
        { url = rootUrl ++ "zomdataapp/highscores/"
        , expect = Http.expectJson HighscoreList (highscoreDecoder hs)
        } 

--Decoder functions

--collecting the stats into one record to be sent to the model

assignStats : Stats -> Upgrade -> Upgrade -> Upgrade -> Upgrade -> Upgrade -> Upgrade -> Upgrade -> Upgrade -> Stats
assignStats stats v a d m f s p h = { stats | speed = v
                                    , armor = a
                                    , damage = d
                                    , muzzleV = m
                                    , fireRate = f
                                    , spread = s
                                    , penetration = p
                                    , healthRegen = h
                                    }

--decodes the individual stat values

--decodes the json received and sets it to a record in order to be inserted into the model

userDecoder : UserInfo -> Decode.Decoder UserInfo
userDecoder ui = Decode.map3 (\d c s -> { ui | day = d, cash = c, score = s } )
                 (Decode.field "day" Decode.int)
                 (Decode.field "cash" Decode.int)
                 (Decode.field "score" Decode.int)

upgradeDecoder = Decode.map3 (\x y z -> { value = x, progress = y, cost = z, click = False } )
    ( Decode.field "value" Decode.float )
    ( Decode.field "progress" Decode.float )
    ( Decode.field "cost" Decode.int )

--decodes the stats which have nested stat values encoded inside

statsDecoder : Stats -> Decode.Decoder Stats
statsDecoder stats = Decode.map8 ( assignStats stats )
    (Decode.field "speed" upgradeDecoder)
    (Decode.field "armor" upgradeDecoder)
    (Decode.field "damage" upgradeDecoder)
    (Decode.field "muzzleV" upgradeDecoder)
    (Decode.field "fireRate" upgradeDecoder)
    (Decode.field "spread" upgradeDecoder)
    (Decode.field "penetration" upgradeDecoder)
    (Decode.field "healthRegen" upgradeDecoder)


{- Due to the highscore list being a top 10 list and the max decoder map being 8 values, the top 8 usernames,
   scores and days survived are pulled before the bottom 2, and they are turned into a Decoder value. This decoder value
   is then decoded and assigned to a record in order to be sent to the model. The Highscore type alias is used in order to
   not care about dealing with setting up the exact format of the highscore type. Instead pre-existing highscore record is
   sent and modified in order to be received back to the game.
-}

highscoreDecoder : Highscores -> Decode.Decoder Highscores
highscoreDecoder hs = 
    let top8names = Decode.map8 ( high8Names hs )
            (Decode.field "n1" Decode.string)
            (Decode.field "n2" Decode.string)
            (Decode.field "n3" Decode.string)
            (Decode.field "n4" Decode.string)
            (Decode.field "n5" Decode.string)
            (Decode.field "n6" Decode.string)
            (Decode.field "n7" Decode.string)
            (Decode.field "n8" Decode.string)
        bot2names = Decode.map2 ( low2Names hs )
            (Decode.field "n9" Decode.string)
            (Decode.field "n10" Decode.string)
        top8scores = Decode.map8 ( high8Scores hs )
            (Decode.field "s1" Decode.int)
            (Decode.field "s2" Decode.int)
            (Decode.field "s3" Decode.int)
            (Decode.field "s4" Decode.int)
            (Decode.field "s5" Decode.int)
            (Decode.field "s6" Decode.int)
            (Decode.field "s7" Decode.int)
            (Decode.field "s8" Decode.int)
        bot2scores = Decode.map2 ( low2Scores hs )
            (Decode.field "s9" Decode.int)
            (Decode.field "s10" Decode.int)
        top8days = Decode.map8 ( high8Days hs )
            (Decode.field "d1" Decode.int)
            (Decode.field "d2" Decode.int)
            (Decode.field "d3" Decode.int)
            (Decode.field "d4" Decode.int)
            (Decode.field "d5" Decode.int)
            (Decode.field "d6" Decode.int)
            (Decode.field "d7" Decode.int)
            (Decode.field "d8" Decode.int)
        bot2days = Decode.map2 ( low2Days hs )
            (Decode.field "d9" Decode.int)
            (Decode.field "d10" Decode.int)
    in Decode.map6 combineScores top8names bot2names top8scores bot2scores top8days bot2days

high8Names : Highscores -> String -> String -> String -> String -> String -> String -> String -> String -> Highscores
high8Names hs a b c d e f g h = { hs | n1 = a
                                , n2 = b
                                , n3 = c
                                , n4 = d
                                , n5 = e
                                , n6 = f
                                , n7 = g
                                , n8 = h
                                }

low2Names : Highscores -> String -> String -> Highscores
low2Names hs a b = { hs | n9 = a
                    , n10 = b
                    }

high8Scores : Highscores -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Highscores
high8Scores hs a b c d e f g h = { hs | s1 = a
                                 , s2 = b
                                 , s3 = c
                                 , s4 = d
                                 , s5 = e
                                 , s6 = f
                                 , s7 = g
                                 , s8 = h
                                 }

low2Scores : Highscores -> Int -> Int -> Highscores
low2Scores hs a b = { hs | s9 = a
                     , s10 = b
                     }

high8Days : Highscores -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int -> Highscores
high8Days hs a b c d e f g h = { hs | d1 = a
                               , d2 = b
                               , d3 = c
                               , d4 = d
                               , d5 = e
                               , d6 = f
                               , d7 = g
                               , d8 = h
                               }

low2Days : Highscores -> Int -> Int -> Highscores
low2Days hs a b = { hs | d9 = a
                   , d10 = b
                   }


combineScores h8n b2n h8s b2s h8d b2d = { n1 = h8n.n1, n2 = h8n.n2, n3 = h8n.n3, n4 = h8n.n4, n5 = h8n.n5
                                        , n6 = h8n.n6, n7 = h8n.n7, n8 = h8n.n8, n9 = b2n.n9, n10 = b2n.n10
                                        , s1 = h8s.s1, s2 = h8s.s2, s3 = h8s.s3, s4 = h8s.s4, s5 = h8s.s5
                                        , s6 = h8s.s6, s7 = h8s.s7, s8 = h8s.s8, s9 = b2s.s9, s10 = b2s.s10
                                        , d1 = h8d.d1, d2 = h8d.d2, d3 = h8d.d3, d4 = h8d.d4, d5 = h8d.d5
                                        , d6 = h8d.d6, d7 = h8d.d7, d8 = h8d.d8, d9 = b2d.d9, d10 = b2d.d10
                                        }

--error message displayed if the server responds with an error

handleError : Http.Error -> String
handleError error =
    case error of
        Http.BadUrl url   ->  "bad url: " ++ url

        Http.Timeout      ->  "timeout"

        Http.NetworkError ->  "network error"

        Http.BadStatus i  ->  "bad status " ++ String.fromInt i

        Http.BadBody body ->  "bad body " ++ body

--Upgrade cost/max progress check

canBuy : Int -> Int -> Float -> ( Bool, Bool )
canBuy cash cost progress = mapBoth (\_ -> if cash >= cost then True else False)
                                    (\_ -> if progress < 0.9 then True else False)
                                    (cash, progress)

--Boundries

xBoundry : Float -> Float -> Float --h for hero r for radius
xBoundry h r = if h + r > 905 then 905
              else if h + r < -905 then -905
              else h + r

yBoundry : Float -> Float -> Float --h for hero r for radius
yBoundry h r = if h + r > 475 then 475
              else if h + r < -535 then -535
              else h + r

--Zombie functions

zombieGen : Model -> Random.Generator Zombie    --Generates the zombie with stats determined by the round
zombieGen model =                               --The positions are assigned based on a radius around the player
    Random.map3                                 --The speed is a random multiplier of the zombie speed based on the round.
        (\x y s ->
            { speed = clamp 0 8 (s + toFloat(model.day - 1)/10)
            , x = x
            , y = y
            , colour = green
            , hp = toFloat(10 + 5*(model.day - 1))
            , maxHp = toFloat(10 + 5*(model.day - 1))
            , size = 20
            , dmg = toFloat(3 + model.day - 1)
            , dir =  atan2 y x
            , value = toFloat(2 + 2*(model.day))
            , isHit = 0
            }
        )
        (Random.float ( xBoundry model.heroX (-800) ) ( xBoundry model.heroX 800 ))
        (Random.float ( yBoundry model.heroY (-800) ) ( yBoundry model.heroY 800 ))
        (Random.float 0.5 1.5)


bossZombieGen : Model -> Random.Generator Zombie        --He's bigger, faster and stronger too,
bossZombieGen model =                                   --He's the first member of the zombie crew, Huh!
    Random.map3
        (\x y s ->
            { speed = clamp 0 8 (s + toFloat(model.day - 1)/10)
            , x = x
            , y = y
            , colour = darkGreen
            , hp = toFloat(40 + 5*(model.day - 1))
            , maxHp = toFloat(40 + 5*(model.day - 1))
            , size = 40
            , dmg = toFloat(10 + 2*model.day - 1)
            , dir = (atan2 y x)
            , value = toFloat(10 + 5*(model.day - 1))
            , isHit = 0
            }
        )
        (Random.float ( xBoundry model.heroX (-800) ) ( xBoundry model.heroX 800 ))
        (Random.float ( yBoundry model.heroY (-800) ) ( yBoundry model.heroY 800 ))
        (Random.float 1 2)

--Using the player's position to direct the zombies. This function is called once per browser update and used 
--to cool off the zombie redness if the zombie has been hit by a bullet

updatePosition : Float -> Float -> Float -> Zombie -> Zombie
updatePosition x y feeding zombie =
    let
        dx = x - zombie.x
        dy = y - zombie.y
        vx = if sqrt(dx^2 +dy^2) > 12 then dx / sqrt (dx^2 + dy^2) else 0
        vy = if sqrt(dx^2 +dy^2) > 12 then dy / sqrt (dx^2 + dy^2) else 0
        dir = if sqrt(dx^2 +dy^2) > 12 then (atan2 dy dx) + 3*pi/2 else (atan2 (dy+feeding) (dx) ) + 3*pi/2
        cool = if zombie.isHit > 0 then (zombie.isHit - 1/30) else 0
    in
    { zombie | x = xBoundry zombie.x (vx * zombie.speed), y = yBoundry zombie.y (vy * zombie.speed), dir = dir, isHit = cool }

updatePositions : Float -> Float -> Float -> Army -> Army
updatePositions x y feeding army =
    List.map (updatePosition x y feeding) army

--Damage on hero multiplier

nomNom : Model -> Zombie -> Bool
nomNom model zombie = if abs(model.heroX - zombie.x) < zombie.size + 25
                      && abs(model.heroY - zombie.y) < zombie.size + 25
                      then True else False
                      
nom : Model -> Army -> Float
nom model army = army |> List.filter (nomNom model)
                      |> List.map (\z -> z.dmg)
                      |> List.foldl (+) 0


--Gun functions

makeBullet : Model -> Bullet
makeBullet model = let stats = model.upgrades
                       dmg = stats.damage
                   in { x = model.heroX
                      , y = model.heroY
                      , dir = model.heroDir
                      , size = 3 + dmg.progress*5
                      , dmg = model.damage
                      , speed = model.muzzleV
                      , penetration = model.penetration
                      , hitList = []
                      }

angle : Int -> List Bullet -> List Bullet                                       --adding degrees of separation to the bullets shot.
angle a b = if a == 1 then List.map (\c-> { c | dir = c.dir + pi/36 } ) b       --pi/72 is for the central angle for an even # of bullets
            else if a == 2 then List.map (\c-> { c | dir = c.dir - pi/36 } ) b  --pi/36 is for every other bullet
            else if a == 3 then List.map (\c-> { c | dir = c.dir + pi/72 } ) b 
            else List.map (\c-> { c | dir = c.dir - pi/72 } ) b 

--provides cases for shooting a different number of bullets

fire : Model -> Gun
fire model = let bullet = makeBullet model
             in case model.spread of 
                1  -> [bullet]
                2  -> List.concat [ angle 3 [bullet]
                                  , angle 4 [bullet]
                                  ]
                3  -> List.concat [ [bullet]
                                  , angle 1 [bullet]
                                  , angle 2 [bullet]
                                  ]
                4  -> List.concat [ angle 3 [bullet]
                                  , angle 4 [bullet]
                                  , angle 3 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 [bullet]
                                  ]
                5  -> List.concat [ [bullet]
                                  , angle 1 [bullet]
                                  , angle 2 [bullet]
                                  , angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 [bullet]
                                  ]
                6  -> List.concat [ angle 3 [bullet]
                                  , angle 4 [bullet]
                                  , angle 3 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 [bullet]
                                  , angle 3 <| angle 1 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 <| angle 2 [bullet]
                                  ]
                7  -> List.concat [ [bullet]
                                  , angle 1 [bullet]
                                  , angle 2 [bullet]
                                  , angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 [bullet]
                                  , angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 <| angle 2 [bullet]
                                  ]
                8  -> List.concat [ angle 3 [bullet]
                                  , angle 4 [bullet]
                                  , angle 3 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 [bullet]
                                  , angle 3 <| angle 1 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 <| angle 2 [bullet]
                                  , angle 3 <| angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 <| angle 2 <| angle 2 [bullet]
                                  ]
                9  -> List.concat [ [bullet]
                                  , angle 1 [bullet]
                                  , angle 2 [bullet]
                                  , angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 [bullet]
                                  , angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 <| angle 2 [bullet]
                                  , angle 1 <| angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 <| angle 2 <| angle 2 [bullet]
                                  ]
                10 -> List.concat [ angle 3 [bullet]
                                  , angle 4 [bullet]
                                  , angle 3 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 [bullet]
                                  , angle 3 <| angle 1 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 <| angle 2 [bullet]
                                  , angle 3 <| angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 <| angle 2 <| angle 2 [bullet]
                                  , angle 3 <| angle 1 <| angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 4 <| angle 2 <| angle 2 <| angle 2 <| angle 2 [bullet]
                                  ]
                11 -> List.concat [ [bullet]
                                  , angle 1 [bullet]
                                  , angle 2 [bullet]
                                  , angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 [bullet]
                                  , angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 <| angle 2 [bullet]
                                  , angle 1 <| angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 <| angle 2 <| angle 2 [bullet]
                                  , angle 1 <| angle 1 <| angle 1 <| angle 1 <| angle 1 [bullet]
                                  , angle 2 <| angle 2 <| angle 2 <| angle 2 <| angle 2 [bullet]
                                  ]
                _  -> []

--send the bullet in a straight path determined by the player's direction upon shooting

trajectory : Bullet -> Bullet
trajectory bullet = 
    let 
        dx = cos(bullet.dir)
        dy = sin(bullet.dir)
        vx = if sqrt(dx^2 +dy^2) > 0 then dx / sqrt (dx^2 + dy^2) else 0
        vy = if sqrt(dx^2 +dy^2) > 0 then dy / sqrt (dx^2 + dy^2) else 0
    in
    { bullet | x = bullet.x + vx * bullet.speed, y = bullet.y + vy * bullet.speed }

--removes the bullets from the list once they leave the game screen

offScreen : Gun -> Gun
offScreen gun = List.filter (\b -> b.x <= (925 - b.size)
                                && b.x >= (-925 + b.size)
                                && b.y <= (495 - b.size)
                                && b.y >= (-555 + b.size)
                            ) gun

shootGun : Gun -> Gun
shootGun gun =
    List.map trajectory (offScreen gun)

--Hit detection

bOneHit : ( Int, Zombie ) -> Bullet -> Bullet   --sending collision detection information to the bullet involved
bOneHit z b = let zombie = second z
                  zNum = first z
                  bHits = if abs( b.x - zombie.x ) < (zombie.size + b.size) 
                          && abs( b.y - zombie.y ) < (zombie.size + b.size)
                          && not ( List.member zNum b.hitList )
                            then ( b.hitList ++ [zNum], b.penetration - 1 )   --(which zombies are hit, how many more times it can hit a zombie)
                            else ( b.hitList, b.penetration )

             in { b | hitList = (first bHits), penetration = (second bHits) }

zOneHit : Bullet -> ( Int, Zombie ) -> ( Int, Zombie )    --sending collision detection information to the zombie involved
zOneHit b z = let zombie = second z
                  zNum = first z
                  zHits = if abs( b.x - zombie.x ) < (zombie.size + b.size) 
                          && abs( b.y - zombie.y ) < (zombie.size + b.size)
                          && not ( List.member zNum b.hitList )
                            then ( zombie.hp - b.dmg, 1 )   --(damaging the zombie, transparency value for redness to indicate being hit)
                            else ( zombie.hp, zombie.isHit )

             in ( zNum, { zombie | hp = (first zHits), isHit = (second zHits) } )


--This function is checking every zombie in the army against every bullet fired and updating the zombie,
--as well as checking every bullet in the gun against every individual zombie and updating the bullet.

collisions : Gun -> Army -> ( Gun, (Float , Army) )
collisions gun army = let iZombie = List.indexedMap pair army     --indexing the zombies to avoid repetitions in colision detection
                          zHurt = List.map (\z -> List.foldl zOneHit z gun ) iZombie
                          newArmy = List.unzip zHurt |> second
                          zCash = newArmy |> List.filter (\z -> z.hp <= 0.01)
                                          |> List.map (\z -> z.value)
                                          |> List.foldl (+) 0
                          zDeath = newArmy |> List.filter (\z -> z.hp > 0.01)     --dead zombie filter incorporating float num error
                          bPen = List.map (\b -> List.foldl bOneHit b iZombie ) gun
                          bStop = List.filter (\b -> b.penetration > 0) bPen    --dead bullet filter

                      in ( bStop, (zCash, zDeath ) )


--Button colour changes

isClicked : String -> Bool -> ( Color, Color ) 
isClicked button isIt = case isIt of
                            True    -> case button of 
                                            "login" -> (charcoal, darkCharcoal)
                                            "play"  -> (darkRed, red)
                                            "quit"  -> (darkCharcoal, charcoal)
                                            "highScores" -> (darkCharcoal, charcoal)
                                            "upgrade" -> (grey, darkGrey)
                                            _       -> (white, white)
                            False   -> case button of
                                            "login" -> (darkGrey, charcoal)
                                            "play"  -> (red, darkRed)
                                            "quit"  -> (charcoal, darkCharcoal)
                                            "highScores" -> (charcoal, darkCharcoal)
                                            "upgrade" -> (lightGrey, grey)
                                            _       -> (white, white)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
                Tick time (keys, (x,y), (u,v))  -> 
                    let phase = if model.timer == 61 && model.phase == Start 
                                    then Shop
                                else model.phase

                        reload = if model.reload > 0
                                    then model.reload - 1/60
                                 else 0

                        offline = if (model.com == "Offline mode. No progress will be saved." || model.com == "network error") 
                                  && model.poorBoy == 0   --resetting the server communication message once the game starts
                                    then ""
                                  else model.com

                        feeding = 5*sin(20*time)    --zombie wiggle

                        hits = collisions model.gun model.army      --collision detection on eery tick

                        newArmy = hits |> second |> second      --a zombie health check to remove zombie and add cash value
                        addCash = hits |> second |> first

                        damage = nom model newArmy      --hero damage upon touching the player

                        regen = (if model.heroHp < model.heroMaxHp then model.healthRegen else 0)   --regenerate hp

                        score = model.score + List.length model.army - List.length newArmy      --when the zombie list decreases, the score increases proportionally

                        allRagsNoRiches = if model.poorBoy > 0 then model.poorBoy - 1/60 else 0     --display fading poor joke

                    in if model.heroHp > 0
                        then ( { model | phase = phase
                                , com = offline
                                , heroX = if u == 0 && v == 0 then 
                                                xBoundry model.heroX (x*model.heroSpeed)
                                        else if x == 0 && y == 0 then 
                                                xBoundry model.heroX (u*model.heroSpeed)
                                        else model.heroX
                                , heroY = if u == 0 && v == 0 then 
                                                yBoundry model.heroY (y*model.heroSpeed)
                                        else if x == 0 && y == 0 then 
                                                yBoundry model.heroY (v*model.heroSpeed)
                                        else model.heroY
                                , heroHp = clamp 0 model.heroMaxHp (model.heroHp - 1/60*damage + regen)     --adding regen and subtracting dmg form hero hp
                                , army = if model.phase == Start
                                            then updatePositions model.heroX model.heroY feeding newArmy
                                            else []
                                , gun = shootGun (first hits)
                                , reload = reload
                                , cash = model.cash + round(addCash)
                                , score = score
                                , poorBoy = allRagsNoRiches
                                }
                                , if ( model.timer == 2 || modBy (clamp 1 6 (round(4 - toFloat(model.day)/5))) model.timer == 0 ) && model.spawn   --Spawn a zombie once per time interval
                                        then Random.generate NewZombie ( zombieGen model ) 
                                else if model.timer >= 44 && model.timer < 45 && model.spawn                           --Boss Zombie spawn
                                        then Random.generate NewZombie ( bossZombieGen model )
                                else if model.phase == Shop && model.phase /= phase && phase == Start    --Save stats and score upon leaving the shop
                                        then Cmd.batch [ saveStats model.upgrades, saveScore model.userInfo ]
                                else Cmd.none
                             )
                    else update Death ( youDied model )   --if the hero's hp drops to 0, end the game and reset the stats to init values
                
                Tock _                  -> ( { model | timer = model.timer + 1, poorBoy = if model.timer == 0 || model.timer == 4 then 3 else model.poorBoy, spawn = True }, Cmd.none ) --increment the timer and reset the spawn enabler once per second

                Play                    -> ( { model | day = model.day + 1, phase = Start, timer = 0, army = [], heroHp = model.heroMaxHp }, Cmd.none )
                
                StatsButton             -> ( { model | phase = Scoreboard }, Cmd.none )
                
                ShopButton              -> ( { model | phase = Shop }, Cmd.none )

                Death                   -> update Save model    --Saves the reset stats. This means that the scores in the server will only increase if you survive the round
                
                Direction (dirX, dirY)  -> ( { model | heroDir = atan2 (dirY-model.heroY) (dirX-model.heroX) }, Cmd.none )
                
                NewZombie newZombie     -> ( { model | army = [newZombie] ++ model.army, spawn = False }, Cmd.none)
                
                Shoot _ -> let newBullets = fire model 
                           in if model.reload == 0 
                                then ( { model | gun = newBullets ++ model.gun, reload = (4.5*model.fireRate) }, Cmd.none )
                                else ( model, Cmd.none )
                
{- Each stat increase undergoes a check to see if the user can buy it before increasing the value, progress fraction, decreasing the
   user's cash amount and assigning all the stats to the player model. A joke is displayed if the cash check comes back false, and 
   max stat message is displayed if the progress-not-full check comes back false. -}

                SpeedUp     -> let stats = model.upgrades
                                   oldStat = stats.speed
                                   newSpeed = oldStat.value + 1
                                   newProgress = oldStat.progress + 0.1
                                   cost = oldStat.cost*2
                                   allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                               in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                        (True, True)    -> ({ model | heroSpeed = newSpeed
                                                            , cash = model.cash - oldStat.cost
                                                            , upgrades = { stats | speed = { oldStat | value = newSpeed, progress = newProgress, cost = cost } } }, Cmd.none )
                                        (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                        (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )
                
                ArmorUp     -> let stats = model.upgrades
                                   oldStat = stats.armor
                                   newArmor = oldStat.value + 100
                                   newProgress = oldStat.progress + 0.1
                                   cost = oldStat.cost*2
                                   allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                               in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                        (True, True)    -> ({ model | heroMaxHp = newArmor
                                                            , cash = model.cash - oldStat.cost
                                                            , upgrades = { stats | armor = { oldStat | value = newArmor, progress = newProgress, cost = cost } } }, Cmd.none )
                                        (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                        (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )
                
                MuzzleVUp   -> let stats = model.upgrades
                                   oldStat = stats.muzzleV
                                   newMuzzleV = oldStat.value + 5
                                   newProgress = oldStat.progress + 0.1
                                   cost = oldStat.cost*2
                                   allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                               in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                        (True, True)    -> ({ model | muzzleV = newMuzzleV
                                                            , cash = model.cash - oldStat.cost
                                                            , upgrades = { stats | muzzleV = { oldStat | value = newMuzzleV, progress = newProgress, cost = cost } } }, Cmd.none )
                                        (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                        (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )
                
                DamageUp    -> let stats = model.upgrades
                                   oldStat = stats.damage
                                   newDamage = oldStat.value + 3
                                   newProgress = oldStat.progress + 0.1
                                   cost = oldStat.cost*2
                                   allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                               in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                        (True, True)    -> ({ model | damage = newDamage
                                                            , cash = model.cash - oldStat.cost
                                                            , upgrades = { stats | damage = { oldStat | value = newDamage, progress = newProgress, cost = cost } } }, Cmd.none )
                                        (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                        (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )
                
                FireRateUp  -> let stats = model.upgrades
                                   oldStat = stats.fireRate
                                   newFireRate = oldStat.value - 1/30
                                   newProgress = oldStat.progress + 0.1
                                   cost = oldStat.cost*2
                                   allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                               in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                        (True, True)    -> ({ model | fireRate = newFireRate
                                                            , cash = model.cash - oldStat.cost
                                                            , upgrades = { stats | fireRate = { oldStat | value = newFireRate, progress = newProgress, cost = cost } } }, Cmd.none )
                                        (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                        (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )
                
                SpreadUp    -> let stats = model.upgrades
                                   oldStat = stats.spread
                                   newSpread = oldStat.value + 1
                                   newProgress = oldStat.progress + 0.1
                                   cost = oldStat.cost*2
                                   allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                               in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                        (True, True)    -> ({ model | spread = round(newSpread)
                                                            , cash = model.cash - oldStat.cost
                                                            , upgrades = { stats | spread = { oldStat | value = newSpread, progress = newProgress, cost = cost } } }, Cmd.none )
                                        (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                        (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )
                
                PenetrationUp   -> let stats = model.upgrades
                                       oldStat = stats.penetration
                                       newPenetration = oldStat.value + 1
                                       newProgress = oldStat.progress + 0.1
                                       cost = oldStat.cost*2
                                       allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                                   in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                            (True, True)    -> ({ model | penetration = round(newPenetration)
                                                                , cash = model.cash - oldStat.cost
                                                                , upgrades = { stats | penetration = { oldStat | value = newPenetration, progress = newProgress, cost = cost } } }, Cmd.none )
                                            (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                            (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )
                
                HealthRegenUp   -> let stats = model.upgrades
                                       oldStat = stats.healthRegen
                                       newHealthRegen = oldStat.value + 1/120
                                       newProgress = oldStat.progress + 0.1
                                       cost = oldStat.cost*2
                                       allRagsNoRiches = if oldStat.cost > model.cash then 2.5 else model.poorBoy
                                   in case (canBuy model.cash oldStat.cost oldStat.progress) of
                                            (True, True)    -> ({ model | healthRegen = newHealthRegen
                                                                , cash = model.cash - oldStat.cost
                                                                , upgrades = { stats | healthRegen = { oldStat | value = newHealthRegen, progress = newProgress, cost = cost } } }, Cmd.none )
                                            (False, True)   -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.int 0 9) )
                                            (_, False)      -> ( { model | poorBoy = allRagsNoRiches }, Random.generate Joke (Random.constant 10) )

                MouseDown button    -> let stats = model.upgrades
                                           oldSpeed = stats.speed
                                           oldArmor = stats.armor
                                           oldMuzzleV = stats.muzzleV
                                           oldDamage = stats.damage
                                           oldFireRate = stats.fireRate
                                           oldSpread = stats.spread
                                           oldPenetration = stats.penetration
                                           oldHealthRegen = stats.healthRegen
                                       in case button of
                                            "speed"       -> ( { model | upgrades = { stats | speed = { oldSpeed | click = True } } } , Cmd.none )
                                            "armor"       -> ( { model | upgrades = { stats | armor = { oldArmor | click = True } } } , Cmd.none )
                                            "muzzleV"     -> ( { model | upgrades = { stats | muzzleV = { oldMuzzleV | click = True } } } , Cmd.none )
                                            "damage"      -> ( { model | upgrades = { stats | damage = { oldDamage | click = True } } } , Cmd.none )
                                            "fireRate"    -> ( { model | upgrades = { stats | fireRate = { oldFireRate | click = True } } } , Cmd.none )
                                            "shotgun"     -> ( { model | upgrades = { stats | spread = { oldSpread | click = True } } } , Cmd.none )
                                            "penetration" -> ( { model | upgrades = { stats | penetration = { oldPenetration | click = True } } } , Cmd.none )
                                            "healthRegen" -> ( { model | upgrades = { stats | healthRegen = { oldHealthRegen | click = True } } } , Cmd.none )
                                            "play"        -> ( { model | pPress = True }, Cmd.none )
                                            "highScores"  -> ( { model | sPress = True }, Cmd.none )
                                            "quit"        -> ( { model | qPress = True }, Cmd.none )
                                            "hold"        -> ( { model | hold = True }, Cmd.none )
                                            _ -> ( model , Cmd.none )

                MouseUp     -> let stats = model.upgrades
                                   oldSpeed = stats.speed
                                   oldArmor = stats.armor
                                   oldMuzzleV = stats.muzzleV
                                   oldDamage = stats.damage
                                   oldFireRate = stats.fireRate
                                   oldSpread = stats.spread
                                   oldPenetration = stats.penetration
                                   oldHealthRegen = stats.healthRegen
                               in ( { model | pPress = False
                                            , sPress = False
                                            , qPress = False
                                            , hold = False
                                            , upgrades = { stats | speed = { oldSpeed | click = False }
                                                                 , armor = { oldArmor | click = False }
                                                                 , muzzleV = { oldMuzzleV | click = False }
                                                                 , damage = { oldDamage | click = False }
                                                                 , fireRate = { oldFireRate | click = False }
                                                                 , spread = { oldSpread | click = False }
                                                                 , penetration = { oldPenetration | click = False }
                                                                 , healthRegen = { oldHealthRegen | click = False }
                                                                 } } , Cmd.none )

                Joke a  -> case a of 
                            0 -> ( { model | joke = ("I'd suggest you buy a calculator but,","I don't think you can even afford that") }, Cmd.none )
                            1 -> ( { model | joke = ("Do you see the price of this?","Forget money, you can't even pay attention.") }, Cmd.none )
                            2 -> ( { model | joke = ("Zombies don't have to worry about money.","Have you ever considered that lifestyle?") }, Cmd.none )
                            3 -> ( { model | joke = ("You want this for $" ++ String.fromInt(model.cash) ++ "???","But how will I afford my Maserati?") }, Cmd.none )
                            4 -> ( { model | joke = ("Not enough money eh?","I also accept unborn children.") }, Cmd.none )
                            5 -> ( { model | joke = ("Don't like the price? Go cry outside.","Maybe the zombies will feel bad for you.") }, Cmd.none )
                            6 -> ( { model | joke = ("You like upgrades?","I like money.") }, Cmd.none )
                            7 -> ( { model | joke = ("Before you try to steal from me, just","remember that I have all the upgrades.") }, Cmd.none )
                            8 -> ( { model | joke = ("No money?","No upgrades!") }, Cmd.none )
                            9 -> ( { model | joke = ("You need more cash to buy more upgrades!","I have quite a bit of money riding on you.") }, Cmd.none )
                            _ -> ( { model | joke = ("You have already maxed this stat", "") }, Cmd.none )

                Name name           -> ( { model | name = name }, Cmd.none )

                Password pass       -> ( { model | pass = pass }, Cmd.none )

                Password2 pass2     -> ( { model | pass2 = pass2 }, Cmd.none )

                Signup              -> ( model, addUser model.name model.pass )    --If the user does not log in then they will play offline and no progress will be saved

                Login               -> let stat = getStats model.upgrades model.name model.pass     --Accessing the user's saved data upon successful login
                                           prog = getScore model.userInfo model.name model.pass
                                       in ( { model | phase = Start, day = model.day + 1 }, Cmd.batch [ stat, prog ] )
                
                Attempt             -> ( { model | day = model.day + 1 }, attemptLogin model.name model.pass )   --Check to determine if the user exists

                Save                -> let stat = saveStats model.upgrades
                                           prog = saveScore model.userInfo
                                       in ( model, Cmd.batch [ stat, prog ] )

                JsonUser result     -> case result of
                                        Ok newUser -> 
                                            ( { model | day = newUser.day
                                              , cash = newUser.cash
                                              , score = newUser.score
                                              }, Cmd.none )

                                        Err error ->
                                            ( { model | com = handleError error }, Cmd.none )

                JsonStats result    -> case result of
                                            Ok loadStats -> let stats = model.upgrades
                                                                speed = loadStats.speed
                                                                armor = loadStats.armor
                                                                muzzleV = loadStats.muzzleV
                                                                damage = loadStats.damage
                                                                fireRate = loadStats.fireRate
                                                                spread = loadStats.spread
                                                                penetration = loadStats.penetration
                                                                healthRegen = loadStats.healthRegen
                                                            in ( { model | upgrades = { stats | speed=speed, armor=armor, muzzleV=muzzleV, damage=damage
                                                                                      , fireRate=fireRate, spread=spread, penetration=penetration, healthRegen=healthRegen
                                                                                      }
                                                                , heroSpeed = speed.value
                                                                , heroHp = armor.value
                                                                , heroMaxHp = armor.value
                                                                , muzzleV = muzzleV.value
                                                                , damage = damage.value
                                                                , fireRate = fireRate.value
                                                                , spread = round( spread.value )
                                                                , penetration = round( penetration.value )
                                                                , healthRegen = healthRegen.value
                                                                }, Cmd.none )

                                            Err error -> ( { model | com = handleError error }, Cmd.none )

                GotResponse result  -> case result of
                                            Ok "LoginFailed" -> ( { model | com = "invalid username/password" }, Cmd.none )
                                            
                                            Ok "Offline" -> ( { model | poorBoy = 3, com = "Offline mode. No progress will be saved." }, Cmd.none )     --if the user enters no username then the game will assume to play
                                                                                                                                                        --offline and no progress will be saved.
                                            Ok "LoggedOut" -> ( { model | name = "", pass = "", pass2 = "", phase = Title }, Cmd.none )
                                            
                                            Ok "ProgressSaved" -> ( { model | com = "Progress Saved" }, Cmd.none )

                                            Ok "LoggedIn" -> update Login model

                                            Ok _ -> ( model, Cmd.none )

                                            Err error -> ( { model | com = handleError error, phase = if (String.left 3 model.com) == "bad" then Start else model.phase }, Cmd.none )

                HighscoreList result -> case result of 
                                            Ok list -> let highS = { n1 = list.n1, n2 = list.n2, n3 = list.n3, n4 = list.n4, n5 = list.n5
                                                                   , n6 = list.n6, n7 = list.n7, n8 = list.n8, n9 = list.n9, n10 = list.n10
                                                                   , s1 = list.s1, s2 = list.s2, s3 = list.s3, s4 = list.s4, s5 = list.s5
                                                                   , s6 = list.s6, s7 = list.s7, s8 = list.s8, s9 = list.s9, s10 = list.s10
                                                                   , d1 = list.d1, d2 = list.d2, d3 = list.d3, d4 = list.d4, d5 = list.d5
                                                                   , d6 = list.d6, d7 = list.d7, d8 = list.d8, d9 = list.d9, d10 = list.d10
                                                                   }
                                                         in ( { model | hScores = highS }, Cmd.none )
            
                                            Err error -> ( { model | com = handleError error }, Cmd.none )

                Logout              ->  let stat = saveStats model.upgrades      --Saving stats and progress upon logout while resetting username and password ingame
                                            prog = saveScore model.userInfo
                                        in ({ model | phase = Title }, Cmd.batch [ stat, prog, logOut ] )

                MakeRequest _       -> let stat = saveStats model.upgrades      --Saving stats and progress upon leaving the webpage or url change
                                           prog = saveScore model.userInfo
                                       in ( model, Cmd.batch [ stat, prog ] )
                
                UrlChange _         -> let stat = saveStats model.upgrades
                                           prog = saveScore model.userInfo
                                       in ( model, Cmd.batch [ stat, prog ] )

                NoOp                -> ( model, Cmd.none )

--Game phase selector to determine which model to view.

view : Model -> { title : String, body : Collage Msg }
view model =
    case model.phase of
        Title  -> titleScreen model

        Start  -> gameScreen model
        
        Shop   -> shopScreen model

        Scoreboard -> scoreScreen model

        Died   -> deathScreen model


viewInput : String -> String -> String -> (String -> msg) -> Html.Html msg
viewInput t p v toMsg =
    Html.input [ Att.type_ t
               , Att.placeholder p
               , Att.value v
               , (HEvents.onInput toMsg)
               , Att.style "background-color" "transparent"
               , Att.style "height" "85px"
               , Att.style "width" "100%" 
               , Att.style "font-size" "60px"] []


verify : String -> String -> Bool
verify pass p2 = if (pass == p2) && (p2 /= "") then True else False


titleScreen : Model -> { title : String, body : Collage Msg }
titleScreen model = let title = "ZomZom"
                        body = collage 1920 1200 shapes
                        shapes = [ border
                                    , statusBar
                                    , welcome
                                    --, playButton
                                    , form
                                    --, auth
                                    ]
        
        
                        statusBar = group [ header, under ]
                        header = rectangle 1920 100
                            |> filled charcoal
                            |> move (0,550)
                        under = line (-960,500) (960,500) |> outlined (solid 10) darkCharcoal
        
        
                        border = group [ back, b1, b2, b3 ]
                        b1 = rectangle 1895 1175
                            |> outlined (solid 50) darkCharcoal
                        b2 = rectangle 1905 1185
                            |> outlined (solid 30) charcoal
                        b3 = rectangle 1915 1190
                            |> outlined (solid 10) darkGreen
                        back = rect 1920 1200 
                            |> filled lightGrey
        
                        welcome = text("ZomZom")
                            |> bold
                            |> underline
                            |> centered
                            |> customFont "Ariel"
                            |> sansserif
                            |> size 150
                            |> filled black
                            |> addOutline (solid 4) darkGreen
                            |> move (0, 150)

                        form = group [ frame, com, name ] |> move (-250, 0)
                        name = html 500 400 ( Html.div []
                                            [ Html.div [] [ viewInput "text" "Username" model.name Name ]
                                            , Html.div [] [ viewInput "password" "Password" model.pass Password ]
                                            , Html.div [] [ viewInput "password" "Verify Password" model.pass2 Password2 ]
                                            , Html.div [] [ Html.button [ Att.disabled (verify model.pass model.pass2)
                                                                        , HEvents.onClick (Signup)
                                                                        , Att.style "background-color" "darkgreen"
                                                                        , Att.style "height" "85px"
                                                                        , Att.style "width" "40%" 
                                                                        , Att.style "font-size" "40px"
                                                                        , Att.style "text-align" "center"
                                                                        , Att.style "margin" "auto"
                                                                        , Att.style "width" "50%"
                                                                        , Att.style "border" "15px solid green"
                                                                        , Att.style "padding" "10px"
                                                                        , Att.style "border-radius" "15px;"]
                                                          [ Html.text "Sign Up" ] 
                                                          , Html.button [ HEvents.onClick (Attempt)
                                                                        , Att.style "background-color" "darkgreen"
                                                                        , Att.style "height" "85px"
                                                                        , Att.style "width" "40%" 
                                                                        , Att.style "font-size" "40px"
                                                                        , Att.style "text-align" "center"
                                                                        , Att.style "margin" "auto"
                                                                        , Att.style "width" "50%"
                                                                        , Att.style "border" "15px solid green"
                                                                        , Att.style "padding" "10px" 
                                                                        , Att.style "border-radius" "15px;"]
                                                          [ Html.text "Log In" ] ] ] )
                        com = text (model.com)
                            |> bold
                            |> size 25
                            |> filled red
                            |> move (50,10)
                        frame = roundedRect 510 438 5
                            |> filled darkCharcoal
                            |> addOutline (solid 10) charcoal
                            |> move (250, -144)
        
        
                    in { title = title , body = body }

{- A zombie is rendered according to it's size (boss zombies are big) and an overlay of a red zombie
   is present and activated upon being hit by a bullet to indicate damage. Health bars are generated with the
   size being based on the zombie's max hp.
-}

oneZombie : Zombie -> Shape Msg
oneZombie zombie =
    group [ group [ roundedRect (3*zombie.size/5) (9*zombie.size/10) (2*zombie.size/5)    
                    |> filled darkGreen
                    |> move ( 3*zombie.size/4, 3*zombie.size/5 )
                  , roundedRect (3*zombie.size/5) (9*zombie.size/10) (2*zombie.size/5)
                    |> filled darkGreen
                    |> move ( -3*zombie.size/4, 3*zombie.size/5 )
                  , roundedRect (3*zombie.size/5) (9*zombie.size/10) (2*zombie.size/5)   
                            |> filled red
                            |> makeTransparent zombie.isHit
                            |> move ( 3*zombie.size/4, 3*zombie.size/5 )
                  , roundedRect (3*zombie.size/5) (9*zombie.size/10) (2*zombie.size/5)
                            |> filled red
                            |> makeTransparent zombie.isHit
                            |> move ( -3*zombie.size/4, 3*zombie.size/5 )
                  , circle zombie.size      
                    |> filled zombie.colour
                  , circle zombie.size
                        |> filled red
                        |> makeTransparent zombie.isHit
                  ] |> notifyMouseMoveAt Direction
                    |> rotate ( zombie.dir )
                  , roundedRect (zombie.hp) 12 2        --health bar
                        |> filled red
                        |> move (0,zombie.size + 10)
                        |> move ((zombie.hp-zombie.maxHp)/2, 0)
                  , roundedRect (zombie.maxHp) 12 2
                    |> outlined (solid 2) black
                    |> move (0,zombie.size + 10)
                  ] |> move ( zombie.x, zombie.y )
            
--making the zombies into an always changing shape

renderZombies : Army -> Shape Msg
renderZombies army =
    group <| List.map oneZombie army


{- A bullet is drawn that increases in size with the damage stat and points in the direction
   that the player was pointing in upon shooting.
-}

oneBullet : Bullet -> Shape Msg
oneBullet bullet =
    group [ roundedRect (2*bullet.size) (2*bullet.size+2) 2
            |> filled darkYellow
          , circle bullet.size
            |> filled darkYellow
            |> move ( 0, (bullet.size + 1) )
          ] |> notifyMouseMoveAt Direction
            |> rotate ( bullet.dir + 3*pi/2)
            |> move ( bullet.x, bullet.y )

renderBullets : Gun -> Shape Msg
renderBullets gun =
    group <| List.map oneBullet gun

--the meat of the game is drawn here

gameScreen : Model -> { title : String, body : Collage Msg }
gameScreen model = let 
                        title = "ZomZom"
                        body = collage 1920 1200 shapes
                        shapes = [ border
                                 , statusBar
                                 , timer
                                 , score
                                 , health
                                 , cash
                                 , instruct
                                 , instruct2
                                 , renderBullets model.gun
                                 , hero
                                 , renderZombies model.army
                                 , progSaved
                                 ] 

                        instruct = if model.day == 0
                                    then group [
                                            text("Arrow Keys or WASD to Move")
                                            |> bold
                                            |> centered
                                            |> customFont "Ariel"
                                            |> sansserif
                                            |> size 100
                                            |> filled black
                                            |> move (0, 150) ]
                                        |> makeTransparent (if model.timer <= 4 then model.poorBoy else 0)
                                    else group []

                        instruct2 = if model.day == 0
                                    then group [
                                            text("Click to Shoot")     --Play again appears after "You died" and remains on the screen
                                            |> bold
                                            |> centered
                                            |> customFont "Ariel"
                                            |> sansserif
                                            |> size 100
                                            |> filled black
                                            |> move (0, 150) ]
                                        |> makeTransparent (if model.timer > 4 && model.timer <= 8 then model.poorBoy else 0)
                                    else group []

                        statusBar = group [ header, under ]
                        header = rectangle 1920 100
                                  |> filled charcoal
                                  |> move (0,550)
                        under = line (-960,500) (960,500) |> outlined (solid 10) darkCharcoal

                        border = group [ back, b1, b2, b3 ]
                            |> notifyMouseMoveAt Direction
                        b1 = rectangle 1895 1175
                            |> outlined (solid 50) darkCharcoal
                        b2 = rectangle 1905 1185
                            |> outlined (solid 30) charcoal
                        b3 = rectangle 1915 1190
                            |> outlined (solid 10) darkGreen
                        back = rect 1920 1200 
                            |> filled lightGrey
                        
                        progSaved = if model.poorBoy > 0 && model.day > 0
                                        then group [        --Progress Saved displays first and then fades
                                            text("Progress Saved")
                                                |> bold
                                                |> centered
                                                |> customFont "Ariel"
                                                |> sansserif
                                                |> size 200
                                                |> filled black
                                                |> addOutline (solid 8) darkRed
                                                |> move (0, 150) ]
                                            |> makeTransparent model.poorBoy
                                        else group []


                        timer = text ("Time: " ++ String.fromInt (clamp 0 60 model.timer))
                            |> bold
                            |> size 60
                            |> sansserif
                            |> filled white
                            |> move ( 700, 525 )
                        score = text ("Kill Count: " ++ String.fromInt(model.score))
                            |> bold
                            |> size 60
                            |> sansserif
                            |> filled darkRed
                            |> move ( -275, 525 ) 
                        cash = text ("Cash: " ++ String.fromInt(model.cash))
                            |> bold
                            |> size 60
                            |> sansserif
                            |> filled darkYellow
                            |> move ( 250, 525 ) 
                        
                        health = group [ roundedRect (450*(model.heroHp/model.heroMaxHp)) 50 2
                                           |> filled (rgba 0 255 0 (model.heroHp/model.heroMaxHp))
                                           |> move (-225*(1-model.heroHp/model.heroMaxHp), 0)
                                       , roundedRect (450*(model.heroHp/model.heroMaxHp)) 50 2
                                           |> filled (rgba 255 0 0 (1-model.heroHp/model.heroMaxHp))
                                           |> move (-225*(1-model.heroHp/model.heroMaxHp), 0)
                                       , roundedRect 450 50 2
                                           |> outlined (solid 4) black
                                       , text("+")
                                           |> customFont "Ariel"
                                           |> sansserif
                                           |> alignLeft
                                           |> bold
                                           |> size 90
                                           |> filled red
                                           |> move (-290, -30)
                                       ] |> move (-600,550)

                        hero = group [ gun, shoulders, head ] 
                                     |> rotate ( model.heroDir - pi/2 )
                                     |> move (model.heroX, model.heroY)
                                     |> notifyMouseMoveAt Direction

                        head = circle 23
                                |> filled darkBrown
                                
                        shoulders = roundedRect 60 30 13
                                |> filled darkBlue

                        gun = rectangle 8 15
                                |> filled darkCharcoal
                                |> move (10,25)

                        
                        in { title = title , body = body }


--Drawing the progress bars for each stat and fillign it to the statbox

speedStatBar : Upgrade -> Shape Msg
speedStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                              |> filled green
                              |> move (-225*(1-stat.progress), 0)
                          , roundedRect 450 50 2
                              |> outlined (solid 4) black
                          , text("Speed")
                                 |> customFont "Ariel"
                                 |> sansserif
                                 |> alignLeft
                                 |> size 35
                                 |> filled black
                                 |> move (-225, -56)
                          ] |> move (0,345)
armorStatBar : Upgrade -> Shape Msg
armorStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                              |> filled green
                              |> move (-225*(1-stat.progress), 0)
                          , roundedRect 450 50 2
                              |> outlined (solid 4) black
                          , text("Armor")
                                |> customFont "Ariel"
                                |> sansserif
                                |> alignLeft
                                |> size 35
                                |> filled black
                                |> move (-225, -56)
                          ] |> move (0,245)
healthRegenStatBar : Upgrade -> Shape Msg
healthRegenStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                                    |> filled green
                                    |> move (-225*(1-stat.progress), 0)
                                , roundedRect 450 50 2
                                    |> outlined (solid 4) black
                                , text("Health Regen")
                                    |> customFont "Ariel"
                                    |> sansserif
                                    |> alignLeft
                                    |> size 35
                                    |> filled black
                                    |> move (-225, -56)
                                ] |> move (0,145)
damageStatBar : Upgrade -> Shape Msg
damageStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                               |> filled green
                               |> move (-225*(1-stat.progress), 0)
                           , roundedRect 450 50 2
                               |> outlined (solid 4) black
                           , text("Damage")
                                |> customFont "Ariel"
                                |> sansserif
                                |> alignLeft
                                |> size 35
                                |> filled black
                                |> move (-225, -56)
                           ] |> move (0,45)
muzzleVStatBar : Upgrade -> Shape Msg
muzzleVStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                                       |> filled green
                                       |> move (-225*(1-stat.progress), 0)
                                   , roundedRect 450 50 2
                                       |> outlined (solid 4) black
                                   , text("Muzzle Velocity")
                                        |> customFont "Ariel"
                                        |> sansserif
                                        |> alignLeft
                                        |> size 35
                                        |> filled black
                                        |> move (-225, -56)
                                   ] |> move (0,-65)
penetrationStatBar : Upgrade -> Shape Msg
penetrationStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                                    |> filled green
                                    |> move (-225*(1-stat.progress), 0)
                                , roundedRect 450 50 2
                                    |> outlined (solid 4) black
                                , text("Penetration")
                                    |> customFont "Ariel"
                                    |> sansserif
                                    |> alignLeft
                                    |> size 35
                                    |> filled black
                                    |> move (-225, -56)
                                ] |> move (0,-165)
fireRateStatBar : Upgrade -> Shape Msg
fireRateStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                                |> filled green
                                |> move (-225*(1-stat.progress), 0)
                            , roundedRect 450 50 2
                                |> outlined (solid 4) black
                             , text("Fire Rate")
                                |> customFont "Ariel"
                                |> sansserif
                                |> alignLeft
                                |> size 35
                                |> filled black
                                |> move (-225, -56)
                             ] |> move (0,-265)
spreadStatBar : Upgrade -> Shape Msg
spreadStatBar stat = group [ roundedRect (450*(stat.progress)) 50 2
                                |> filled green
                                |> move (-225*(1-stat.progress), 0)
                            , roundedRect 450 50 2
                                |> outlined (solid 4) black
                            , text("Shotgun Spread")
                                |> customFont "Ariel"
                                |> sansserif
                                |> alignLeft
                                |> size 35
                                |> filled black
                                |> move (-225, -55)
                            ] |> move (0,-358)


statsBox : Model -> Shape Msg
statsBox model = let 
                    border = rect 500 900
                        |> outlined (solid 10) black
                        |> move (0,20)
                    statsTitle = text("Stats")
                        |> bold
                        |> underline
                        |> customFont "Ariel"
                        |> sansserif
                        |> centered
                        |> size 60
                        |> filled black
                        |> move (-155, 400)
                    stats = model.upgrades

                 in group [ border
                          , statsTitle
                          , speedStatBar stats.speed
                          , armorStatBar stats.armor
                          , healthRegenStatBar stats.healthRegen
                          , damageStatBar stats.damage
                          , muzzleVStatBar stats.muzzleV
                          , penetrationStatBar stats.penetration
                          , fireRateStatBar stats.fireRate
                          , spreadStatBar stats.spread
                          ] |> move (650, 13)

--shop in between rounds to buy upgrades, quit or display highscores

shopScreen : Model -> { title : String, body : Collage Msg }
shopScreen model = let  title = "ZomZom"
                        body = collage 1920 1200 shapes
                        shapes = [ border
                                 , statusBar
                                 , playButton
                                 , welcome
                                 , upgrades
                                 , statsBox model
                                 , highScoresButton
                                 , quitButton
                                 , day
                                 , score
                                 , cash
                                 , no
                                 , no2
                                 ]


                        statusBar = group [ header, under ]
                        header = rectangle 1920 100
                                  |> filled charcoal
                                  |> move (0,550)
                        under = line (-960,500) (960,500) |> outlined (solid 10) darkCharcoal

                        border = group [ back, b1, b2, b3 ]
                            |> notifyMouseMoveAt Direction
                        b1 = rectangle 1895 1175
                            |> outlined (solid 50) darkCharcoal
                        b2 = rectangle 1905 1185
                            |> outlined (solid 30) charcoal
                        b3 = rectangle 1915 1190
                            |> outlined (solid 10) darkGreen
                        back = rect 1920 1200 
                            |> filled lightGrey
                        
                        day = text ("Day: " ++ String.fromInt model.day)
                            |> bold
                            |> size 60
                            |> sansserif
                            |> filled white
                            |> move ( 700, 525 )
                        score = text ("Kill Count: " ++ String.fromInt(model.score))
                            |> bold
                            |> size 60
                            |> sansserif
                            |> filled darkRed
                            |> move ( -275, 525 ) 
                        cash = text ("Cash: " ++ String.fromInt(model.cash))
                            |> bold
                            |> size 60
                            |> sansserif
                            |> filled darkYellow
                            |> move ( 250, 525 ) 

                        welcome = text("Secret Shop")
                            |> bold
                            |> underline
                            |> alignRight
                            |> customFont "Ariel"
                            |> sansserif
                            |> size 150
                            |> filled black
                            |> addOutline (solid 5) darkBrown
                            |> move (20, 330)

                        playButton = group [button, start]      --button to start next wave
                            |> notifyTap Play
                            |> notifyMouseDown (MouseDown "play")
                            |> notifyMouseUp MouseUp
                            |> move (625,-490)
                        button = roundedRect 450 100 30 
                            |> filled ( first ( isClicked "play" model.pPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "play" model.pPress ) )
                        start = text("Next Wave")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 60
                            |> filled black
                            |> addOutline (solid 3) darkRed
                            |> move (0,-20)

                        quitButton = group [qButton, quit]      --logout button returns to title screen
                            |> notifyTap Logout
                            |> notifyMouseDown (MouseDown "quit")
                            |> notifyMouseUp MouseUp
                            |> move (-625,-490)
                        qButton = roundedRect 450 100 30 
                            |> filled ( first ( isClicked "quit" model.qPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "quit" model.qPress ) )
                        quit = text("Quit")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 60
                            |> filled black
                            |> addOutline (solid 3) darkCharcoal
                            |> move (0,-20)

                        highScoresButton = group [sButton, highScores]      --stats button displays your progress and highscores
                            |> notifyTap StatsButton
                            |> notifyMouseDown (MouseDown "highScores")
                            |> notifyMouseUp MouseUp
                            |> move (0,-490)
                        sButton = roundedRect 450 100 30 
                            |> filled ( first ( isClicked "highScores" model.sPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "highScores" model.sPress ) )
                        highScores = text("High Scores")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 60
                            |> filled black
                            |> addOutline (solid 3) darkCharcoal
                            |> move (0,-20)

                        no = if model.poorBoy > 0 then      --activates when the user is too poor for an upgrade
                                text(first model.joke)
                                    |> bold
                                    |> centered
                                    |> customFont "Ariel"
                                    |> sansserif
                                    |> size 75
                                    |> filled lightRed
                                    |> addOutline (solid 5) black
                                    |> makeTransparent model.poorBoy
                                    |> move (-125, -75)
                                else group []
                        no2 = if model.poorBoy > 0 then
                                text(second model.joke)
                                    |> bold
                                    |> centered
                                    |> customFont "Ariel"
                                    |> sansserif
                                    |> size 75
                                    |> filled lightRed
                                    |> addOutline (solid 5) black
                                    |> makeTransparent model.poorBoy
                                    |> move (-125, -170)
                                else group []

                        stats = model.upgrades      --gathered to assign the bool click to each shape changing its colour
                        speed = stats.speed
                        armor = stats.armor
                        muzzleV = stats.muzzleV
                        damage = stats.damage
                        fireRate = stats.fireRate
                        spread = stats.spread
                        penetration = stats.penetration
                        healthRegen = stats.healthRegen

                        upgrades = group [ speedUpgrade
                                         , armorUpgrade
                                         , damageUpgrade
                                         , healthRegenUpgrade
                                         , muzzleVUpgrade
                                         , penetrationUpgrade
                                         , fireRateUpgrade
                                         , shotgunUpgrade
                                         ] |> move (-150,40)

                        speedUpgrade = group [ upgradeBox1      --each stat button calls the stat-up message
                                             , upgradeBox11
                                             , speedImg
                                             , speedText1
                                             , speedText2
                                             , speedCost
                                             ] 
                                             |> move (-590,20)
                                             |> notifyTap SpeedUp
                                             |> notifyMouseDown ( MouseDown "speed" )
                                             |> notifyMouseUp MouseUp
                        upgradeBox11 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox1 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" speed.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" speed.click ) )
                        speedImg = html 230 220 ( Html.img [ Att.src "boots.png", Att.width 220, Att.height 190 ] [] )
                            |> move (-110, 130)
                        speedText1 = text ("Pumped up kicks.")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        speedText2 = text ("Better run!")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        speedCost = text ( if speed.progress < 0.9 then ("$" ++ (String.fromInt speed.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)

                        armorUpgrade = group [ upgradeBox2
                                             , upgradeBox22
                                             , armorImg
                                             , armorText1
                                             , armorText2
                                             , armorCost
                                             ]
                                             |> move (-270,20)
                                             |> notifyTap ArmorUp
                                             |> notifyMouseDown ( MouseDown "armor" )
                                             |> notifyMouseUp MouseUp
                        upgradeBox22 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox2 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" armor.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" armor.click ) )
                        armorImg = html 200 170 ( Html.img [ Att.src "armor.png", Att.width 200, Att.height 170 ] [] )
                            |> move (-100, 100)
                        armorText1 = text ("Kevlar vest will stop")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        armorText2 = text ("the claws... I think.")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        armorCost = text ( if armor.progress < 0.9 then ("$" ++ (String.fromInt armor.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)

                        damageUpgrade = group [ upgradeBox3
                                              , upgradeBox33
                                              , damageImg
                                              , damageText1
                                              , damageText2
                                              , damageCost
                                              ]
                                              |> move (50,20)
                                              |> notifyTap DamageUp
                                              |> notifyMouseDown ( MouseDown "damage" )
                                              |> notifyMouseUp MouseUp
                        upgradeBox33 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox3 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" damage.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" damage.click ) )
                        damageImg = html 240 220 ( Html.img [ Att.src "damage.png", Att.width 240, Att.height 150 ] [] )
                            |> move (-122, 90)
                        damageText1 = text ("Bigger bullets,")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        damageText2 = text ("bigger damage!")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        damageCost = text ( if damage.progress < 0.9 then ("$" ++ (String.fromInt damage.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)

                        healthRegenUpgrade = group [ upgradeBox4
                                                   , upgradeBox44
                                                   , healthRegenImg
                                                   , healthRegenText1
                                                   , healthRegenText2
                                                   , healthRegenCost
                                                   ]
                                                   |> move (370,20)
                                                   |> notifyTap HealthRegenUp
                                                   |> notifyMouseDown ( MouseDown "healthRegen" )
                                                   |> notifyMouseUp MouseUp
                        upgradeBox44 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox4 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" healthRegen.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" healthRegen.click ) )
                        healthRegenImg = html 230 220 ( Html.img [ Att.src "healthRegen.png", Att.width 200, Att.height 200 ] [] )
                            |> move (-100, 130)
                        healthRegenText1 = text ("Experimental drug to")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        healthRegenText2 = text ("regenerate health")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        healthRegenCost = text ( if healthRegen.progress < 0.9 then ("$" ++ (String.fromInt healthRegen.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)

                        muzzleVUpgrade = group [ upgradeBox5
                                                      , upgradeBox55
                                                      , muzzleVImg
                                                      , muzzleVText1
                                                      , muzzleVText2
                                                      , muzzleVCost
                                                      ]
                                                      |> move (-590,-300)
                                                      |> notifyTap MuzzleVUp
                                                      |> notifyMouseDown ( MouseDown "muzzleV" )
                                                      |> notifyMouseUp MouseUp
                        upgradeBox55 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox5 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" muzzleV.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" muzzleV.click ) )
                        muzzleVImg = html 230 220 ( Html.img [ Att.src "muzzleVelocity.png", Att.width 230, Att.height 90 ] [] )
                            |> move (-110, 80)
                        muzzleVText1 = text ("How do bullets fly")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        muzzleVText2 = text ("faster? Magic.")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        muzzleVCost = text ( if muzzleV.progress < 0.9 then ("$" ++ (String.fromInt muzzleV.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)

                        penetrationUpgrade = group [ upgradeBox6
                                                   , upgradeBox66
                                                   , penetrationImg
                                                   , penetrationText1
                                                   , penetrationText2
                                                   , penetrationCost
                                                   ]
                                                   |> move (-270,-300)
                                                   |> notifyTap PenetrationUp
                                                   |> notifyMouseDown ( MouseDown "penetration" )
                                                   |> notifyMouseUp MouseUp
                        upgradeBox66 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox6 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" penetration.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" penetration.click ) )
                        penetrationImg = html 250 250 ( Html.img [ Att.src "penetration.png", Att.width 250, Att.height 250 ] [] )
                            |> move (-110, 140)
                        penetrationText1 = text ("Kill 2 zombies with 1")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        penetrationText2 = text ("bullet! Or 3 or 4 or...")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        penetrationCost = text ( if penetration.progress < 0.9 then ("$" ++ (String.fromInt penetration.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)

                        fireRateUpgrade = group [ upgradeBox7
                                                , upgradeBox77
                                                , fireRateImg
                                                , fireRateText1
                                                , fireRateText2
                                                , fireRateCost
                                                ]
                                                |> move (50,-300)
                                                |> notifyTap FireRateUp
                                                |> notifyMouseDown ( MouseDown "fireRate" )
                                                |> notifyMouseUp MouseUp
                        upgradeBox77 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox7 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" fireRate.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" fireRate.click ) )
                        fireRateImg = html 230 150 ( Html.img [ Att.src "fireRate.png", Att.width 230, Att.height 150 ] [] )
                            |> move (-110, 100)
                        fireRateText1 = text ("Faster trigger means")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        fireRateText2 = text ("faster deaths")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        fireRateCost = text ( if fireRate.progress < 0.9 then ("$" ++ (String.fromInt fireRate.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)

                        shotgunUpgrade = group [ upgradeBox8
                                               , upgradeBox88
                                               , shotgunImg
                                               , shotgunText1
                                               , shotgunText2
                                               , shotgunCost
                                               ]
                                               |> move (370,-300)
                                               |> notifyTap SpreadUp
                                               |> notifyMouseDown ( MouseDown "shotgun" )
                                               |> notifyMouseUp MouseUp
                        upgradeBox88 = roundedRect 315 315 15 |> outlined (solid 5) black
                        upgradeBox8 = roundedRect 300 300 10
                            |> filled ( first ( isClicked "upgrade" spread.click ) )
                            |> addOutline (solid 20) ( second ( isClicked "upgrade" spread.click ) )
                        shotgunImg = html 260 220 ( Html.img [ Att.src "shotgun.png", Att.width 260, Att.height 80 ] [] )
                            |> move (-130, 70)
                        shotgunText1 = text ("Spread the love,")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -100)
                        shotgunText2 = text ("and the carnage")
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 30
                            |> filled black
                            |> move (0, -130)
                        shotgunCost = text ( if spread.progress < 0.9 then ("$" ++ (String.fromInt spread.cost)) else ("Sold Out") )
                            |> customFont "Ariel"
                            |> bold
                            |> sansserif
                            |> alignLeft
                            |> size 30
                            |> filled darkGreen
                            |> move (-120, 110)


             in { title = title , body = body }


--Highscore and name formatting

displayName : String -> Shape Msg
displayName n = text(String.left 10 n) |> bold |> size 45 |> alignLeft |> filled black

displayScore : Int -> Shape Msg
displayScore i = if i == 0 then text("") |> bold |> size 50 |> alignLeft |> filled red
                    else text( String.fromInt(i) ) |> bold |> size 50 |> alignLeft |> filled red

--highscore and stats display screen

scoreScreen : Model -> { title : String, body : Collage Msg }
scoreScreen model = let 
                        title = "ZomZom"
                        body = collage 1920 1200 shapes
                        shapes = [ border
                                 , day
                                 , score
                                 , cash
                                 , statusBar
                                 , welcome
                                 , playButton
                                 , quitButton
                                 , shopButton
                                 , table
                                 ]

                        statusBar = group [ header, under ]
                        header = rectangle 1920 100
                                  |> filled charcoal
                                  |> move (0,550)
                        under = line (-960,500) (960,500) |> outlined (solid 10) darkCharcoal


                        border = group [ back, b1, b2, b3 ]
                                |> notifyMouseMoveAt Direction
                        b1 = rectangle 1895 1175
                            |> outlined (solid 50) darkCharcoal
                        b2 = rectangle 1905 1185
                            |> outlined (solid 30) charcoal
                        b3 = rectangle 1915 1190
                            |> outlined (solid 10) darkGreen
                        back = rect 1920 1200 
                            |> filled lightGrey
                        
                        --these are the user's stats to compare with other highscores

                        day = text ("Days Survived: " ++ String.fromInt model.day)
                            |> bold
                            |> alignLeft
                            |> size 100
                            |> sansserif
                            |> filled black
                            |> move ( -850, 150 )
                        score = text ("Your Kill Count: " ++ String.fromInt(model.score))
                            |> bold
                            |> alignLeft
                            |> size 100
                            |> sansserif
                            |> filled black
                            |> addOutline (solid 5) darkRed
                            |> move ( -850, -50 ) 
                        cash = text ("Your Cash: " ++ String.fromInt(model.cash))
                            |> bold
                            |> alignLeft
                            |> size 100
                            |> sansserif
                            |> filled black
                            |> addOutline (solid 5) darkYellow
                            |> move ( -850, -250 ) 

                        welcome = text("Statistics")
                            |> bold
                            |> underline
                            |> alignRight
                            |> customFont "Ariel"
                            |> sansserif
                            |> size 150
                            |> filled black
                            |> addOutline (solid 5) darkBrown
                            |> move (20, 330)

                        playButton = group [button, start]  --begin next round
                            |> notifyTap Play
                            |> notifyMouseDown (MouseDown "play")
                            |> notifyMouseUp MouseUp
                            |> move (625,-490)
                        button = roundedRect 450 100 30 
                            |> filled ( first ( isClicked "play" model.pPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "play" model.pPress ) )
                        start = text("Next Wave")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 60
                            |> filled black
                            |> addOutline (solid 3) darkRed
                            |> move (0,-20)

                        quitButton = group [qButton, quit]      --logout button
                            --|> notifyTap Logout
                            |> notifyMouseDown (MouseDown "quit")
                            |> notifyMouseUp MouseUp
                            |> move (-625,-490)
                        qButton = roundedRect 450 100 30 
                            |> filled ( first ( isClicked "quit" model.qPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "quit" model.qPress ) )
                        quit = text("Quit")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 60
                            |> filled black
                            |> addOutline (solid 3) darkCharcoal
                            |> move (0,-20)

                        shopButton = group [sButton, shop]      --return to shop
                            |> notifyTap ShopButton
                            |> notifyMouseDown (MouseDown "highScores")
                            |> notifyMouseUp MouseUp
                            |> move (0,-490)
                        sButton = roundedRect 450 100 30 
                            |> filled ( first ( isClicked "highScores" model.sPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "highScores" model.sPress ) )
                        shop = text("Shop")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 60
                            |> filled black
                            |> addOutline (solid 3) darkCharcoal
                            |> move (0,-20)

                        --the usernames (n*) score (s*) and days survived (d*) are displayed as shapes

                        hScores = model.hScores
                        n1 = displayName hScores.n1   |> move (-400, 300)
                        n2 = displayName hScores.n2   |> move (-400, 235)
                        n3 = displayName hScores.n3   |> move (-400, 170)
                        n4 = displayName hScores.n4   |> move (-400, 105)
                        n5 = displayName hScores.n5   |> move (-400, 40)
                        n6 = displayName hScores.n6   |> move (-400, -25)
                        n7 = displayName hScores.n7   |> move (-400, -90)
                        n8 = displayName hScores.n8   |> move (-400, -155)
                        n9 = displayName hScores.n9   |> move (-400, -220)
                        n10 = displayName hScores.n10 |> move (-400, -285)
                        s1 = displayScore hScores.s1   |> move (25, 300)
                        s2 = displayScore hScores.s2   |> move (25, 235)
                        s3 = displayScore hScores.s3   |> move (25, 170)
                        s4 = displayScore hScores.s4   |> move (25, 105)
                        s5 = displayScore hScores.s5   |> move (25, 40)
                        s6 = displayScore hScores.s6   |> move (25, -25)
                        s7 = displayScore hScores.s7   |> move (25, -90)
                        s8 = displayScore hScores.s8   |> move (25, -155)
                        s9 = displayScore hScores.s9   |> move (25, -220)
                        s10 = displayScore hScores.s10 |> move (25, -285)
                        d1 = displayScore hScores.d1   |> move (165, 300)
                        d2 = displayScore hScores.d2   |> move (165, 235)
                        d3 = displayScore hScores.d3   |> move (165, 170)
                        d4 = displayScore hScores.d4   |> move (165, 105)
                        d5 = displayScore hScores.d5   |> move (165, 40)
                        d6 = displayScore hScores.d6   |> move (165, -25)
                        d7 = displayScore hScores.d7   |> move (165, -90)
                        d8 = displayScore hScores.d8   |> move (165, -155)
                        d9 = displayScore hScores.d9   |> move (165, -220)
                        d10 = displayScore hScores.d10 |> move (165, -285)
                        l0 = line (-420, 350 ) (275, 350 ) |> outlined (solid 10) black 
                        l1 = line (-420, 285 ) (275, 285 ) |> outlined (solid 10) black 
                        l2 = line (-420, 220 ) (275, 220 ) |> outlined (solid 10) black 
                        l3 = line (-420, 155 ) (275, 155 ) |> outlined (solid 10) black 
                        l4 = line (-420, 90  ) (275, 90  ) |> outlined (solid 10) black 
                        l5 = line (-420, 25  ) (275, 25  ) |> outlined (solid 10) black
                        l6 = line (-420, -40 ) (275, -40 ) |> outlined (solid 10) black 
                        l7 = line (-420, -105) (275, -105) |> outlined (solid 10) black 
                        l8 = line (-420, -170) (275, -170) |> outlined (solid 10) black
                        l9 = line (-420, -235) (275, -235) |> outlined (solid 10) black
                        l10 =line (-420, -300) (275, -300) |> outlined (solid 10) black
                        lv1 = line (0, 350) (0, -300) |> outlined (solid 10) black
                        lv2 = line (140, 350) (140, -300) |> outlined (solid 10) black

                        --collecting scores and table borders

                        scores = group [ n1, n2, n3, n4, n5, n6, n7, n8, n9, n10
                                       , s1, s2, s3, s4, s5, s6, s7, s8, s9, s10
                                       , d1, d2, d3, d4, d5, d6, d7, d8, d9, d10
                                       , l0, l1, l2, l3, l4, l5, l6, l7, l8, l9
                                       , l10, lv1, lv2
                                       ] |> move (75,-20)

                        edges = rect 700 900
                            |> outlined (solid 10) black
                            |> move (0,20)
                        hs = text("High Scores")
                            |> bold
                            |> underline
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 60
                            |> filled black
                            |> move (0, 410)
                        names = text("Username")
                            |> bold
                            |> underline
                            |> customFont "Ariel"
                            |> sansserif
                            |> alignLeft
                            |> size 50
                            |> filled black
                            |> move (-300, 350)
                        kills = text("Kills")
                            |> bold
                            |> underline
                            |> customFont "Ariel"
                            |> sansserif
                            |> alignRight
                            |> size 50
                            |> filled black
                            |> move (180, 350)
                        days = text("Days")
                            |> bold
                            |> underline
                            |> customFont "Ariel"
                            |> sansserif
                            |> alignRight
                            |> size 50
                            |> filled black
                            |> move (335, 350)

                        table = group [ hs, names, kills, days, scores, edges ]
                            |> move (560, 13)

             in { title = title , body = body }

--game over, play again?

deathScreen : Model -> { title : String, body : Collage Msg }
deathScreen model = let title = "ZomZom"
                        body = collage 1920 1200 shapes
                        shapes = [ border
                                    , statusBar
                                    , theEnd
                                    , playAgain
                                    , yes
                                    , no
                                    ]
        
        
                        statusBar = group [ header, under ]
                        header = rectangle 1920 100
                            |> filled charcoal
                            |> move (0,550)
                        under = line (-960,500) (960,500) |> outlined (solid 10) darkCharcoal
        
        
                        border = group [ back, b1, b2, b3 ]
                        b1 = rectangle 1895 1175
                            |> outlined (solid 50) darkCharcoal
                        b2 = rectangle 1905 1185
                            |> outlined (solid 30) charcoal
                        b3 = rectangle 1915 1190
                            |> outlined (solid 10) darkGreen
                        back = rect 1920 1200 
                            |> filled lightGrey

                        theEnd = group [        --You died displays first and then fades
                            text("You Died")
                                |> bold
                                |> centered
                                |> customFont "Ariel"
                                |> sansserif
                                |> size 200
                                |> filled black
                                |> addOutline (solid 8) darkRed
                                |> move (0, 150) ]
                            |> makeTransparent model.poorBoy

                        playAgain = text("Play Again?")     --Play again appears after "You died" and remains on the screen
                            |> bold
                            |> centered
                            |> customFont "Ariel"
                            |> sansserif
                            |> size 200
                            |> filled darkRed
                            |> addOutline (solid 8) black
                            |> move (0, 150) 
                            |> makeTransparent (1-3/model.poorBoy)

                        yes = group [yesButton, start]      --return to game start screen
                            |> notifyTap Play
                            |> notifyMouseDown (MouseDown "play")
                            |> notifyMouseUp MouseUp
                            |> move (250,-100)
                        yesButton = roundedRect 400 150 30
                            |> filled ( first ( isClicked "play" model.pPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "play" model.pPress ) )
                        start = text("Yes")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 100
                            |> filled black
                            |> move (0,-30)
        
                        no = group [noButton, quit]     --return to login screen
                            --|> notifyTap Logout
                            |> notifyMouseDown (MouseDown "quit")
                            |> notifyMouseUp MouseUp
                            |> move (-250,-100)
                        noButton = roundedRect 400 150 30
                            |> filled ( first ( isClicked "quit" model.qPress ) )
                            |> addOutline (solid 20) ( second ( isClicked "quit" model.qPress ) )
                        quit = text("No")
                            |> bold
                            |> customFont "Ariel"
                            |> sansserif
                            |> centered
                            |> size 100
                            |> filled black
                            |> move (0,-30)
                            
        
        
                    in { title = title , body = body }

{- Subscribed to clicking anywhere to shoot.
   When the mouse button is held down a variable is set to true which allows the shoot message to be called 
   on an interval depending on the user's fireRate stat. 
   On mouseUp the MouseUp message is called to release the hold.
   The time subscription is used to begin a new timer ever time the phase returns to Start indicating a new wave.
-}

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch [ if model.phase == Start then BEvents.onClick( Decode.succeed ( Shoot (Time.millisToPosix 1) ) ) else Sub.none
                                , if model.phase == Start then BEvents.onMouseDown( Decode.succeed (MouseDown "hold") ) else Sub.none
                                , BEvents.onMouseUp( Decode.succeed MouseUp )
                                , if model.phase == Start && model.hold then Time.every (2750*model.fireRate) Shoot else Sub.none
                                , if model.phase == Start then Time.every 1000 Tock else Sub.none
                                ]

main : AppWithTick () Model Msg
main = appWithTick Tick
       { init = init
       , update = update
       , view = view
       , subscriptions = subscriptions
       , onUrlRequest = MakeRequest
       , onUrlChange = UrlChange
       } 