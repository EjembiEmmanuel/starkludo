export type OptionsProps = {
  isGame: boolean; // true if game is ongoing, false otherwise
  playersLength: number; // Number of players in current game
  throw: number; // Current number on dice face
  chance: number; // Next player to take action. 0 => red, 1 blue...
  thrown: boolean; // true if dice has been thrown and waiting for action from player, false otherwise
  winners: number[];
  gameCondition: number[];
};
