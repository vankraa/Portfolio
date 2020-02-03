# ZomZoms

A game made in elm is linked to a django server app in order to save scores, progress and stats to a SQL table.
Once the user signs up to the server, they will have access to their own stats. If the username and password
form is not filled the app will continue in offline mode and no progress will be saved upon exiting the game.

The game is hosted on http://ugweb.cas.mcmaster.ca/~vankraa/ZomZoms/PlayZomZoms.html

The server root url is temporarily disabled, including all the urls in the app folder

## Game
-----

-----
### **Main**

Made using MacCASOutreach/graphicsvg AppWithTick with the following format|
```elm
main : AppWithTick () Model Msg
main = appWithTick Tick
       { init = init
       , update = update
       , view = view
       , subscriptions = subscriptions
       , onUrlRequest = MakeRequest
       , onUrlChange = UrlChange
       } 
```

-----
### **Model**
dddwwwwwww
Variable | Type | Use
---|---|---
name | String | The player's username to be sent to the server
pass | String | The player's password used with the username
pass2 | String | The second password is local only to check for typos before sending anything to the server
com | String | The Http message sent from the server is recorded here
phase | Phase | Used to determine which view to display
timer | Int | Timer used only in game phase
day | Int | How many rounds the payer has survived
pPress | Bool | Record if the play button is pressed to change colours
sPress | Bool | Record if the stats button is pressed to change colours
qPress | Bool | Record if the quit button is pressed to change colours
score | Int | How many zombies have been killed
hScores | Highscores | Type alias Highscores has a record of the top 10 usernames ranked in order of zombie kills, as well as their number of kills and number of days survived. 
gun | Gun | Contains a list of bullets created with the shoot function
army | Army | Contains a list of the zombies spawned
spawn | Bool | A variable to switch on and off to control the number of zombies spawned on every call of the **Tick** message
bSpawn | Bool | A variable to switch on and off to control the boss zombie spawn
cash | Int | Player's cash collected
poorBoy | Float | A variable used to control the transparency of a message on the screen to add flare and pzaz to the text
heroX | Float | Player's horizontal position on the screen
heroY | Float | Player's vertical position on the screen
heroDir | Float | Whhich way the player is facing. Used in the creation of bullets to assign their trajectory.
upgrades | Stats | A collection of all of the upgrades used to increase various player attributes
userInfo | UserInfo | A record used for easier Json encoding and decoding
heroSpeed | Float | Easy access to the value of the speed upgrade
heroHp | Float | Easy access to the value of the armor upgrade
heroMaxHp | Float | Used with the heroHp to generate the health bar
healthRegen | Float | Easy access to the value of the healthRegen upgrade
damage | Float | Easy access to the value of the damage upgrade
reload | Float | Easy access to the value of the reload upgrade
fireRate | Float | Easy access to the value of the fireRate upgrade
hold | Bool | Easy access to the value of the hold upgrade
penetration | Int | Easy access to the value of the penetration upgrade
muzzleV | Float | Easy access to the value of the muzzleV upgrade
spread | Int | Easy access to the value of the spread upgrade
joke | (String,String) | 2-line message that displays whenever the user has not enough cash to buy an upgrade

-----
### **Views**

ZomZoms makes use of a **Phase** type with in order to change between different views. The phase type also controls which functions to change variables and respond to command and subscription messages.
```elm
type Phase
    = Title
    | Start
    | Shop
    | Scoreboard
    | Died
```
The view has the GraphicsSVG view of the form:
```elm
view : Model -> { title : String, body : Collage Msg }
```

The view is selected through
```elm
view model =
    case model.phase of
        Title  -> titleScreen model

        Start  -> gameScreen model
        
        Shop   -> shopScreen model

        Scoreboard -> scoreScreen model

        Died   -> deathScreen model
```

#### titleScreen

Displays a form containing a field to enter a username, password and password verification string. A `Sign Up` button is used to call the Signup message to new user to the account. A `Log In` button is used to check for an already existing user and pull their information from the server. A space is also reserved for server communication error messages.

#### gameScreen

The **Start** phase allows for zombies and bullets to be generated and drawn to the screen. The player direction is determined by the position of the mouse and the bullets are drawn facing this direction on every shot. The zombies are created using attributes from the **zombie** type alias. All of the `x` and `y` values for the hero, bullet(s) and zombie(s) are used with the `GraphicsSVG.move` function to determine screen position. The kill count, cash amount and round timer are displayed on the top of the screen. 

#### shopScreen

The shop screen displays buttons that can be clicked in order to increase an attribute based on the player's cash amount. Buttons to quit, see the high score board and continue to the next round are placed at the bottom of the screen. The highscores button calls the server to get an updated highscores list every time it is pressed.

#### scoreScreen

The the top 10 usernames ranked on score as well as their kill count and days survived are rendered in the highscores table. The current player's cash, kills and days survived are also displayed for comparison. A button to return to the shop, quit or begin the next round is also displayed.

#### deathScreen

When the player's hp drops to 0 in the **Start** phase, the phase is changed to **Died.** A message pops up telling them what happened to clear any confusion and the player is asked if they want to play again. If **"No"** is selected, the user is logged out of the system if they are currently logged in and is returned to the title screen. If **"Yes"** is selected, then the stats are reset and the player begins day 1 in the `gameScreen` view.

-----
### **Update**

The update function runs off of the following messages:

- Tick | **Float GetKeyState** 
    - Default graphicsSVG message called once every browser refresh

- Tock | **Time.Posix** 
    - Message called by time subscription to start the clock every round

- MakeRequest | **Browser.UrlRequest** 
    - Called on any browser request. Used to save progress

- UrlChange | **Url.Url** 
    - Called on any browser url change. Also used to save progress

- Play 
    - Begin next round

- StatsButton 
    - Move to the statistics/highscores screen

- ShopButton  
    - Move to the shop

- Death 
    - Call to end game and reset stats

- Direction | **(Float, Float)** 
    - Called on any mouse movement to change the direction of the player

- NewZombie Zombie 
    - Generates a zombie

- Shoot Time.Posix 
    - Generates 1+ bullet(s)

- MouseDown String 
    - Used to repeat the shoot call and to change button colours

- MouseUp 
    - Used to end the repeating shoot call and to change button colours

**Each `StatUp` message is associated to each stat. A check is performed to see if the player can afford the stat. If they can, the value is increased by an amount determined by the stat, the progress fraction is increased by 0.1 and the cash value doubles.**
- SpeedUp   

- ArmorUp    

- MuzzleVUp  

- DamageUp   

- FireRateUp 

- SpreadUp   

- PenetrationUp 

- HealthRegenUp 

- Joke | **Int** 
    - A list of random poor jokes is displayed when a user cant afford an upgrade

- Name | **String**
    - Name, Password and Password2 are just called to display information entered into a field in the login form

- Password  | **String**

- Password2 | **String**

- GotResponse | **(Result Http.Error String)** 
    - Receives Http strings from the server. `"LoginFailed"` comes when the username/password does not match any in the system, `"Offline"` comes if no username or password is entered. `"LoggedOut"` comes if the user ends the session. `"ProgressSaved"` comes to comfirm saving of the user's upgrades and cash/score/day. `"LoggedIn"` comes upon successful login. 

- Save 
    - Save stats by encoding them as Json and sending them in a `Http.POST` 

- JsonUser | **(Result Http.Error UserInfo)** 
    - Receives a Json object to decode and assigns the user's cash, killcount and number of days survived. An error message is sent if there are any problems upon receipt.

- JsonStats | **(Result Http.Error Stats)** 
    - Receives a Json object to decode and assigns the user's stat progress. An error message is sent if there are any problems upon receipt.

- Signup  
    - Button to trigger **addPerson** and add the user to the system.

- Login   
    - Assigns user stats and progress upon successful login.

- Logout  
    - Ends authentication session.

- Attempt 
    - Sends username and password to the server to check authentication for a session.

- HighscoreList | **(Result Http.Error Highscores)** 
    - Calls the server to sort the highscore list and send it here

- NoOp 
    - empty message 

---
### **Subscriptions**


- BEvents.onClick( Decode.succeed ( Shoot (Time.millisToPosix 1) ) )
    - Listens for a click to call *Shoot* and create a bullet. The **Time.Posix** is there in order to let the Msg also be associated with holding the mouse down.
- BEvents.onMouseDown( Decode.succeed (MouseDown "hold") )
    - The "hold" string is sent to change model.hold to *True* which enables the next **Sub.Msg** to be called
- Time.every (4500*model.fireRate) Shoot
    - Fire the gun once per time interval as determined by the player's model.fireRate
- BEvents.onMouseUp( Decode.succeed MouseUp )
    - Stop firing the gun
- Time.every 1000 Tock
    - Used to increment the timer which can be reset on every wave.
---
### **Movement functions, damage and collision detection, and a dead zombie and max bullet penetration filter.**


```elm
updatePosition : Float -> Float -> Float -> Zombie -> Zombie
```
The player's x and y position are used to create a unit vector pointing from the zombie towards the player. The third float is a variable modified by a sin function to make the zombie look like it's doing some really bad things to you. These are applied to each individual zombie submitted by the next function.
```elm
updatePositions : Float -> Float -> Float -> Army -> Army
```
Maps the zombie movement to the entire list of zombies in the army.
```elm
nomNom : Model -> Zombie -> Bool
```
Checks for the distance between the player and the zombie. If it is too small, True is returned to be used with the **nom** function.
```elm
nom : Model -> Army -> Float
```
Maps the **nomNom** damage check to the whole army. It filters the army based on the bool returned by **nomNom,** adds the damage from each zombie and returns a total damage done value that is checked on every cycle in the elm runtime.
```elm
angle : Int -> List Bullet -> List Bullet
```
Adding degrees of separation to the bullets shot. pi/72 is for the central angle for an even # of bullets pi/36 is for every other bullet. **angle** accepts a bullet list in order to make use of the `List.map` function
```elm
fire : Model -> Gun
```
Maps the angle determining function to all the bullets and flattens them into a list to be sent back to the model. This is called by the `Shoot` Msg.
```elm
trajectory : Bullet -> Bullet
```
Moves the bullet in a straight line determined by the initial direction. Movement speed is multiplied by the `muzzleV` stat
```elm
offScreen : Gun -> Gun
```
Removes the bullets from the screen once they reach the border to save some memory.
```elm
bOneHit : ( Int, Zombie ) -> Bullet -> Bullet
```
Checks the position of the bullet with the position of the zombie and if the distance between them is too small the bullet generates a list of all the zombies hit. If the zombie has already been hit by that bullet it can no longer damage the zombie and contines to pass on through without doing anything. Upon collision detection, the penetration number of the bullet is also decreased by 1.
```elm
zOneHit : Bullet -> ( Int, Zombie ) -> ( Int, Zombie )
```
Checks the position of the bullet with the position of the zombie and if the distance between them is too small and the zombie number isn't a part of the bullet's already-ben-hit list, then the bullet damage is subtracted from the zombie's health. The zombie hp is returned along with a transparency multiplier to turn the zombie red upon being hit.
```elm
collisions : Gun -> Army -> ( Gun, (Float , Army) )
```
This function is checking every zombie in the army against every bullet fired and updating the zombie, as well as checking every bullet in the gun against every individual zombie and updating the bullet. It indexes the zombie list to give information as to which zombie is hit. It then separates the zombies from their index and returns an updated army to a greater than 0 zombie hp filter to be sent back to the model. An zombie hp < 0 filter is applied to the damaged army to add up all the values of the zombies in the list and send it to the player's wallet.

---
### Server Communication

## Encoders and Http requests

```elm
encodeUser : String -> String -> Encode.Value
```
Encodes the username and password to a `JSON` object to send to the server securely.
```elm
addUser : String -> String -> Cmd Msg
```
Sends name and password to server for authentication using `Http.post` and registers the user to be saved in the database.
```elm
attemptLogin : String -> String -> Cmd Msg
```
A check to see if the username and password are valid with `Http.post.`
```elm
logOut : Cmd Msg
```
Ends authentication session using `Http.get.` `GET` is used because there is no sensitive information being sent.
```elm
encodeScore : UserInfo -> Encode.Value
```
Encodes the user progress to a `JSON` object be sent to the server.
```elm
saveScore : UserInfo -> Cmd Msg
```
`Http.post` to send the player's progress to the server. 
```elm
encodeOneStat : Upgrade -> Encode.Value
```
Encodes the value, cost and progress of one stat in order to collect the individual information into one json request.
```elm
encodeStats : Stats -> Encode.Value
```
Maps an individual encoded stat to be collected and organized as a json object of json objects to the server for saving progress.
```elm
saveStats : Stats -> Cmd Msg
```
`Http.post` to send the user's current json encoded stats to the server.
```elm
getStats : Stats -> String -> String -> Cmd Msg
```
Get request returns stats if the user is authenticated and nothing if they are not.
```elm
getScore : UserInfo -> String -> String -> Cmd Msg
```
Get request returns score/cash/day# if the user is authenticated, and nothing if they are not.
```elm
getHighscore : Highscores -> Cmd Msg
```
`Http.get` request pulls the highscores from the server

## Decoders

Every decoder uses `Json.Decode.map#` to decode each field of the json object and combine it into a record. The stats and highscores have helper functions *assignStats* and *collectScores* respectively to do this due to the amount of fields being collected in one **Json.Decoder** type.
```elm
userDecoder : UserInfo -> Decode.Decoder UserInfo
```
Decodes the json received and sets it to a record in order to be inserted into the model using the JsonUser **Msg.**
```elm
statsDecoder : Stats -> Decode.Decoder Stats
```
Decodes the stats by mapping to the helper *upgradeDecoder* due to the nested stat values encoded as json objects inside.
```elm
highscoreDecoder : Highscores -> Decode.Decoder Highscores
```
Due to the highscore list being a top 10 list and the max decoder map being 8 values, the top 8 usernames, scores and days survived are pulled before the bottom 2, and they are turned into a Decoder value. This decoder value is then decoded and assigned to a record in order to be sent to the model. The Highscore type alias is used in order to not care about dealing with setting up the exact format of the highscore type. Instead pre-existing highscore record is sent and modified in order to be received back to the game.

---
## Zomdataapp
---
---
### **Model

>```python
>class UserInfoManager(models.Manager):
>    def create_player(self, username, password):
>```
#### ***Usage***
Linked to the *UserInfo* class. `create_player` creates and saves a user with the username and password provided. Then assigns the info field in the `UserInfo` class a `Player` class with the name field set to the username.

---
>```python
>class UserInfo(models.Model):
>```
#### *UserInfo Fields*
A database is created to be associated One-to-One with the user in order to link the user to all of the information without actually extending the User class attributes.
>user = models.OneToOneField(User,
>                                on_delete=models.CASCADE,
>                                primary_key=True)
- One-to-One relation to Django's User class that is created when the user submits their username and password for authentication the first time.
>info = models.OneToOneField('Player', on_delete=models.CASCADE)
- One player database is given to the info field in order to prevent any accidental data spilling between accounts upon sending and reveiving information from the game.
>objects = UserInfoManager()
- The field used to access the `UserInfoManager` in order to create a player.

---
>```python
>class Player(models.Model):
>```
#### *Player Fields*
Defaults are set to the values upon starting the game.
> score = models.IntegerField(default=0)
- The user's zombie kill count
> day = models.IntegerField(default=0)
- The number of days survived
> cash = models.IntegerField(default=20)
- The amount of cash in the user's wallet
> rank = models.IntegerField(null=True)
- A scoreboard ranking to be updated as soon as the user saves their score
> stats = models.ManyToManyField('Stat')
- The stats associated with the user's ingame upgrades
> high_score = models.IntegerField(default=0)
- The user's highest score before being killed by the zombie hoarde
> high_day = models.IntegerField(default=1)
- The user's longest survival time in days (each round is a day) before being killed by the zombie hoarde

---
>```python
>class Stat(models.Model):
>```
#### *Stat Fields*

> stat_name = models.CharField(max_length=11, choices=STATS)
- A name used to make each stat unique for easier queries.
> value = models.FloatField()
- The stat value is the player's attribute that makes them stronger/faster/better.
> progress = models.FloatField()
- The progress is used to put a cap on the stats that can be added
> cost = models.IntegerField()
- The increasing cost of each stat.
> objects = StatManager()
- The link to the stat manager used to settign stats.

---
```python
class StatManager(models.Manager):
        def create_stat(self, stat, value, progress, cost):
        statCreation = self.create(stat_name=stat,
                            value=value,
                            progress=progress,
                            cost=cost,
```
#### ***Usage***
- Creating each unique value of a stat upon receiving data specifying which value to pick as well as the value, progress and cost of a stat.

---
### **Views**
>```python
> def add_user(request):
>```
Recieves a json request `{ 'username' : 'val0', 'password' : 'val1' }` and saves it to the database using the django User Model. Then the user is logged in to begin a session. If an empty username is received then a message is sent telling the game to play in offline mode.

---
>```python
> def attempt_login(request):
>```
Recieves a json request `{ 'name' : 'val0' : 'pass' : 'val1' }` and authenticates and loggs in the user upon success. This sends a message to the game indicating a successful login. If the username is empty nothing is done.

---
>```python
> def save_progress(request):
>```
Receives a json request with the stats in the form `{ "day" : int, "cash" : int, "score" : int }`. Authentication checks if a user is logged into the system and if it is, the player data is pulled from the json request and saved to the user's database entries. For highscore purposes the score/day is only updated if the new score/day is higher than the old. This would fail if the user dies in the game and restarts.

---
>```python
> def save_stats(request):
>```
Receives a json request with the stats in the form 
`{'stat' : {'value' : float, 'progress' : float, 'cash' : int}, 'stat2' : {...}, ...}`. Authentication checks if a user is logged into the system and if it is, the stats are pulled from the json request and saved to the user's database entries.

---
>```python
> def get_stats(request):
>```
Recieves a GET request and uses the session authentication to find the entries in the database corresponding to that user. The values are then encoded as a json response in the form `{'stat' : {'value' : float, 'progress' : float, 'cash' : int}`, 'stat2' : {...}, ...} and sent to the game.

---
>```python
> def get_score(request):
>```
Recieves a get request and uses the session authentication to find the entries in the database corresponding to that user. The values are then encoded as a json response and sent to the game to resume progress.

---
>```python
> def highscore(request):
>```
Recieves a GET request to collect all the users and order them based on score. Then a rank is assigned to the user and a list of names and scores as well as days survived are sent with a key indicating their position in the leaderboard to be accessed by the client.

---
>```python
> def log_out(request):
>```
Ends the current running session.

---
### Urls
```python
urlpatterns = [
    path('add_user/', views.add_user , name = 'zomdataapp-add_user') ,
    path('attempt_login/', views.attempt_login , name = 'zomdataapp-attempt_login') ,
    path('save_stats/', views.save_stats , name = 'zomdataapp-save_stats') ,
    path('save_progress/', views.save_progress , name = 'zomdataapp-save_progress') ,
    path('get_stats/', views.get_stats , name = 'zomdataapp-get_stats') ,
    path('get_score/', views.get_score , name = 'zomdataapp-get_score') ,
    path('highscore/', views.highscore , name = 'zomdataapp-highscore') ,
    path('log_out/', views.log_out , name = 'zomdataapp-log_out') ,
]
```