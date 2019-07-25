# Panda

This is the technical test for applying at PandaScore.

# Prerequisite

You have to export `PANDASCORE_TOKEN` variable

```
export PANDASCORE_TOKEN=TOKEN
```

There are tags for each part.

Don't forget to download all dependencies

```
mix deps.get
```

# Part 1

## How to

```
iex> Panda.upcoming_matches
```

# Part 2

## How to

```
iex> Panda.odds_for_match 547185
```

## Details about how i maked my odds

I am based on 5 stats and each of them is limited by a point max.

+ (1) Confrontation between both teams                       (35 points)
+ (2) Number of tournament played compared with the opponent (5 points)
+ (3) Number of match played compared with the opponent      (10 points)
+ (4) Ratio of match won compared with the opponent          (15 points)
+ (5) Ratio of tournament won compared with the opponent     (35 points)

The sum is equal to 100

For comparing the stats 1,4 and 5 I chose to use the equation detailed here [link](https://sabr.org/research/probabilities-victory-head-head-team-matchups) 

For 2 and 3 a simple division on x played / total of x played by both teams

# Part 3

```
iex> Panda.odds_for_match 547185
```

## Cache

I used Erlang Term Storage or ETS in two places:

+ I record the odds of match with his id
+ As I download the matches of teams, I record this data with team id

## Concurrency

+ I create a map of size 2 (2 opponents) with the whole informations that i need to make an odds. I changed the execution of these operations to async with Task

