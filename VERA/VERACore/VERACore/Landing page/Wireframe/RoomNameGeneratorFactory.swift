//
//  Created by Vonage on 10/7/25.
//

import Foundation

struct RoomNameGeneratorFactory {
    func make() -> RoomNameGenerator {
        RoomNameGenerator(
            categories: [
                .init(words: [
                    "aardvark", "albatross", "alligator", "alpaca", "ant", "anteater", "antelope", "ape",
                    "armadillo", "donkey", "baboon", "badger", "barracuda", "bat", "bear", "beaver", "bee",
                    "bison", "boar", "buffalo", "butterfly", "camel", "capybara", "caribou", "cassowary",
                    "cat", "caterpillar", "cattle", "chamois", "cheetah", "chicken", "chimpanzee", "chinchilla",
                    "chough", "clam", "cobra", "cockroach", "cod", "cormorant", "coyote", "crab", "crane",
                    "crocodile", "crow", "curlew", "deer", "dinosaur", "dog", "dogfish", "dolphin",
                    "dotterel", "dove", "dragonfly", "duck", "dugong", "dunlin", "eagle", "echidna", "eel",
                    "eland", "elephant", "elephantseal", "elk", "emu", "falcon", "ferret", "finch", "fish",
                    "flamingo", "fly", "fox", "frog", "gaur", "gazelle", "gerbil", "giantpanda", "giraffe",
                    "gnat", "gnu", "goat", "goose", "goldfinch", "goldfish", "gorilla", "goshawk", "grasshopper",
                    "grouse", "guanaco", "guineafowl", "guineapig", "gull", "hamster", "hare", "hawk",
                    "hedgehog", "heron", "herring", "hippopotamus", "hornet", "horse", "hummingbird", "hyena",
                    "ibex", "ibis", "jackal", "jaguar", "jay", "jellyfish", "kangaroo", "kingfisher", "koala",
                    "komododragon", "kookabura", "kouprey", "kudu", "lapwing", "lark", "lemur", "leopard",
                    "lion", "llama", "lobster", "locust", "loris", "louse", "lyrebird", "magpie", "mallard",
                    "manatee", "mandrill", "mantis", "marten", "meerkat", "mink", "mole", "mongoose", "monkey",
                    "moose", "mouse", "mosquito", "mule", "narwhal", "newt", "nightingale", "octopus", "okapi",
                    "opossum", "oryx", "ostrich", "otter", "owl", "ox", "oyster", "panther", "parrot",
                    "partridge", "peafowl", "pelican", "penguin", "pheasant", "pig", "pigeon", "polarbear",
                    "pony", "porcupine", "porpoise", "prairiedog", "quail", "quelea", "quetzal", "rabbit",
                    "raccoon", "rail", "ram", "rat", "raven", "reddeer", "redpanda", "reindeer", "rhinoceros",
                    "rook", "salamander", "salmon", "sanddollar", "sandpiper", "sardine", "scorpion",
                    "sealion", "seaurchin", "seahorse", "seal", "shark", "sheep", "shrew", "skunk", "snail",
                    "snake", "sparrow", "spider", "spoonbill", "squid", "squirrel", "starling", "stingray",
                    "stinkbug", "stork", "swallow", "swan", "tapir", "tarsier", "termite", "tiger", "toad",
                    "trout", "turkey", "turtle", "viper", "vulture", "wallaby", "walrus", "wasp",
                    "waterbuffalo", "weasel", "whale", "wolf", "wolverine", "wombat", "woodcock", "woodpecker",
                    "worm", "wren", "yak", "zebra",
                ]),
                .init(words: [
                    "red", "green", "blue", "orange", "purple", "brown", "white", "black", "yellow",
                    "wise", "gentle", "curious", "majestic", "graceful", "playful", "energetic", "regal",
                    "mysterious", "fierce", "cunning", "vibrant", "cuddly", "dazzling", "loyal", "swift",
                    "charming", "whimsical", "serene",
                ]),
            ]
        )
    }
}
