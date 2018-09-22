#include "player.h"

void Player::switchTurn1()
{
    m_player1_turn = !m_player1_turn;
}
void Player::switchTurn2()
{
    m_player2_turn = !m_player2_turn;
}
void Player::switchTurn3()
{
    m_player3_turn = !m_player3_turn;
}
void Player::switchTurn4()
{
    m_player4_turn = !m_player4_turn;
}

bool Player::player1_turn() const
{
    return m_player1_turn;
}

void Player::setPlayer1_turn(bool player1_turn)
{
    m_player1_turn = player1_turn;
}


bool Player::player2_turn() const
{
    return m_player2_turn;
}

void Player::setPlayer2_turn(bool player2_turn)
{
    m_player2_turn = player2_turn;
}

bool Player::player3_turn() const
{
    return m_player3_turn;
}

void Player::setPlayer3_turn(bool player3_turn)
{
    m_player3_turn = player3_turn;
}

bool Player::player4_turn() const
{
    return m_player4_turn;
}

void Player::setPlayer4_turn(bool player4_turn)
{
    m_player4_turn = player4_turn;
}
