{-# LANGUAGE NamedFieldPuns #-}
module Main where

import System.Random

import Control.Monad.Trans
import Control.Monad.State.Lazy
import Data.List
import Data.List.HT

type Hangman a = StateT GameState IO a

-- TODO lookup the definition of the chosen word from an online dictionary,
--      display it at the end of the game, thereby justifying the way that he
--      program tends to call the user a nasty name.
--      LINK: http://services.aonaware.com/DictService/DictService.asmx
--      This looks like this will involve a bit of SOAP. What fun.
--
-- TODO lookup nasty names from the internet to call the user if they lose.

-- Holds a list of true and false values for which the player had already
-- guessed those letters correctly.
--
-- TODO do a total variation of Hangman, which is based on messing around with
--      webservices: find a random word from the database, search and grab an
--      image from Yahoo! images; get the URL and put it into an ASCII-art
--      webservice to convert it into ASCII characters. Present the output to
--      the user to make them recognise what is in the picture.

data GameState = GameState
  { theWord  :: String     -- TODO should be in Reader monad
  , guesses  :: [Char]     -- which characters have been guessed
  , lives    :: Int
  , maxLives :: Int        -- the number of lives at the beginning.
  }

instance Show GameState where
  show (GameState {theWord,guesses,lives,maxLives}) =
    let wordIndicator = map (replaceWith guesses '_') theWord;
        usedIndicator  = "Guessed: {" ++ guesses ++ "}";
        livesIndicator = "Lives:   [" ++ replicate lives 'I' ++ "]"
        spacesFromWordToUsed  = 15 - length wordIndicator
        spacesFromUsedToLives = 14 - length guesses
        spaces = "      "
    in concat [spaces, wordIndicator,
               replicate spacesFromWordToUsed ' ',
               usedIndicator, replicate spacesFromUsedToLives ' ',
               livesIndicator, "\n\n",
               livesIllustrations !! (maxLives-lives)
         ]
    where
      replaceWith cs char c
        | c `elem` cs = c
        | otherwise   = char

data GameResult = Won | Lost | NotWon

-- Game defaults
defaultLives       = 10
startingGameState word = GameState { theWord = word
                                   , guesses = []
                                   , lives = defaultLives
                                   , maxLives = defaultLives }

--
-- This is the loop that runs with state!
-- 1) Repeatedly show prompt for 1 character only.
-- 2) If this is okay, add it into the list of guesses.
-- 3) If there were matches (elem) then do not decrement lives.
-- 4) Check whether the player has won.
--
runHangman :: Hangman ()
runHangman = do

  -- Read state and show the game status
  gs@GameState {theWord,guesses,lives} <- get
  liftIO $ print gs

  -- Keep asking the user for a single character.
  inputChar <- liftIO $ msum $ repeat retrieveChar
  liftIO $ putStr "\n\n"

  -- Decrement lives only if guess was not in the word
  let updateLives = if inputChar `elem` theWord
                    && not (inputChar `elem` guesses) then id else pred

  -- Put state
  let gs' = gs {guesses=guesses `union` [inputChar],lives=updateLives lives}
  put gs'

  case gameResult gs' of
    Won  -> liftIO $ do
      print gs'
      putStr $ wonMessage $ show theWord
    Lost -> liftIO $ do
      print gs'
      putStr $ lostMessage $ show theWord
    _    -> runHangman             -- neither won or lost. Continue.

  where
    -- Asks user for one character only.
    retrieveChar = do
      inLine <- getLine
      if length inLine == 1
        then return $ head inLine
        else do
          putStrLn "Please enter a single character only. Try again."
          mzero -- failure state

    gameResult :: GameState -> GameResult
    gameResult gs@GameState {theWord,guesses,lives} =
      if all (`elem` guesses) theWord
        then Won
        else if lives < 1 then Lost else NotWon

-- At the beginning of the game, I pick a word randomly from a list of words.
-- I have a game
main :: IO ()
main = do
  listOfWords <- getWords "res/words.txt"
  (randomIndex,_) <- newStdGen >>= return . randomR (0,length listOfWords)
  let chosenWord = listOfWords !! randomIndex
  putStrLn introMessage
  putStr "\n\n"
  _ <- execStateT runHangman $ startingGameState chosenWord
  return ()
  where
    getWords filePath  = readFile filePath >>= return . concatMap words . lines

introMessage = unlines [
  "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
  "!                 Hok's Hangman                   !",
  "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
  "Welcome to the gallows...",
  "You'd better get the word right, or else Mr. Stick gets it."
  ]

wonMessage theWord = unlines [
  "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
  "Congratulations, you've won!! You're so smart!",
  "The word was " ++ theWord ++ " -- HOW DID YOU KNOW?!?"
  ]

lostMessage theWord = unlines [
  "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
  "POOR YOU! You've LOST! You're such a dumbass!",
  "The word was " ++ theWord ++ "."
  ]

livesIllustrations = [lives10,lives9,lives8,
                      lives7,lives6,lives5,
                      lives4,lives3,lives2,
                      lives1,theEnd]

lives10 = "             \n" ++
          "             \n" ++
          "             \n" ++
          "             \n" ++
          "             \n" ++
          "             \n" ++
          "             \n"

lives9 =  "             \n" ++
          "             \n" ++
          "             \n" ++
          "             \n" ++
          "             \n" ++
          "             \n" ++
          "-------------\n"

lives8  = "             \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          "-------------\n"

lives7  = "-----------  \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          "-------------\n"

lives6  = "-----------  \n" ++
          " |     |     \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          "-------------\n"

lives5  = "-----------  \n" ++
          " |     |     \n" ++
          " |     O     \n" ++
          " |           \n" ++
          " |           \n" ++
          " |           \n" ++
          "-------------\n"

lives4  = "-----------  \n" ++
          " |     |     \n" ++
          " |     O     \n" ++
          " |     |     \n" ++
          " |           \n" ++
          " |           \n" ++
          "-------------\n"

lives3  = "-----------  \n" ++
          " |     |     \n" ++
          " |     O     \n" ++
          " |    /|     \n" ++
          " |           \n" ++
          " |           \n" ++
          "-------------\n"

lives2  = "-----------  \n" ++
          " |     |     \n" ++
          " |     o     \n" ++
          " |    /|\\    \n" ++
          " |           \n" ++
          " |           \n" ++
          "-------------\n"

lives1  = "-----------  \n" ++
          " |     |     \n" ++
          " |     o     \n" ++
          " |    /|\\    \n" ++
          " |      \\    \n" ++
          " |           \n" ++
          "-------------\n"

theEnd  = "-----------  \n" ++
          " |     |     \n" ++
          " |     O     \n" ++
          " |    /|\\    \n" ++
          " |    / \\    \n" ++
          " |           \n" ++
          "-------------\n"

