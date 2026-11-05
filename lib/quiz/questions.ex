defmodule Quiz.Questions do
  @questions [
    %{
      text: "Vilken planet kallas den röda planeten?",
      choices: ["Venus", "Mars", "Jupiter", "Merkurius"],
      correct_answer: 1
    },
    %{
      text: "Vad heter Sveriges huvudstad?",
      choices: ["Göteborg", "Malmö", "Stockholm", "Uppsala"],
      correct_answer: 2
    },
    %{
      text: "Hur många ben har en spindel?",
      choices: ["Sex", "Sju", "Åtta", "Tio"],
      correct_answer: 2
    },
    %{
      text: "Vilket grundämne har den kemiska beteckningen O?",
      choices: ["Guld", "Syre", "Väte", "Järn"],
      correct_answer: 1
    },
    %{
      text: "Vilket hav ligger mellan Sverige och Finland?",
      choices: ["Nordsjön", "Östersjön", "Medelhavet", "Svarta havet"],
      correct_answer: 1
    }
  ]

  def all, do: @questions
  def count, do: length(@questions)
  def seconds_per_question, do: 20
end
