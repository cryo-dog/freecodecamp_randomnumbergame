#!/bin/bash

# Variables for PSQL
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

WELCOME() {
# Welcome user and aks for name
echo "Enter your username:"
read USERNAME

# Test username length
if [[ ${#USERNAME} -gt 22 ]]
then
  echo "Too long, try agin"
  welcome
else
  echo "Good, let's move on"
  USER_TEST $USERNAME
fi

}

USER_TEST() {
USERNAME=$1
# echo "Opening the test for $USERNAME"
# Get user ID
USERID=$(GET_USER_ID $USERNAME)

#echo "User_id is $USERID"
# If user_id is empty then create new user
# In both cases, move to game afterwards
if [[ -z $USERID ]]
then
  # user does not exist
  NEW_USER $USERNAME
  USERID=$(GET_USER_ID $USERNAME)
  MAINGAME $USERID $USERNAME
else
  # user exists
  DISPLAY_RESULTS $USERID
  MAINGAME $USERID $USERNAME
fi
}

GET_USER_ID() {
  USERNAME=$1
  USERID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
  echo $USERID
}

# If yes, load and display data

DISPLAY_RESULTS() {
USERID=$1
RESULT=$($PSQL "SELECT username, min(tries), count(game_id) FROM users inner join games using(user_id) WHERE user_id = $USERID group by username")
echo $RESULT | while read USERNAME BAR BEST BAR GAMES
do
  # Show results
  echo "Welcome back, $USERNAME! You have played $GAMES games, and your best game took $BEST guesses."
done
}

# If no, display welcome message and create new user

NEW_USER() {
  USERNAME=$1
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  ADDUSER=$($PSQL "INSERT INTO users(username) VALUES ('$USERNAME')")
}

# Game: Guess a secret number between 1-1000

MAINGAME() {
USERID=$1
USERNAME=$2
SECRET=$(( $RANDOM % 1000 + 1 ))
NUMBERIN=0
COUNTER=0


echo "Guess the secret number between 1 and 1000:"

# If not an integer, complain

# Start while loop that continues as long as it is not the secret number

while [ $NUMBERIN -ne $SECRET ]
do
  # Increase counter
  COUNTER=$(($COUNTER + 1))
  # Read input
  read NUMBERIN
  
  # Check if not integer
  if [[ ! $NUMBERIN =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    NUMBERIN=0
  else
    # Test
    # If lower then tell and increase counter
    # If higher, then tell and increase counter
    if [[ $NUMBERIN -gt $SECRET ]]
    then
      echo "It's lower than that, guess again:"
    elif [[ $NUMBERIN -lt $SECRET ]]
    then
      echo "It's higher than that, guess again:"
    fi
  fi

done

  # If hit then tell and save score
  echo "You guessed it in $COUNTER tries. The secret number was $SECRET. Nice job!"

  # Save score
  SAVESCORE=$($PSQL "INSERT INTO games(user_id, tries) VALUES ($USERID, $COUNTER)")

}


# Run starting function 
WELCOME

# Databases needed:
# Users: Contains only usernames and user-id
# Games: Game-ID (PK), user-id (FK), tries