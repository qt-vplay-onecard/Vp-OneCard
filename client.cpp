#include "client.h"

Client::Client(QObject *parent): QObject(parent)
{
    m_port = 1234;
    m_connected = false;
    m_socket=new QTcpSocket();

    QObject::connect(m_socket,&QTcpSocket::readyRead,this, &Client::sockt_recv_data);
    QObject::connect(m_socket,&QTcpSocket::disconnected,this, &Client::socket_disconnect);
}

Client::~Client()
{

}


int Client::receive() const
{
    return m_receive;
}

int Client::sender() const
{
    return m_sender;
}

void Client::setSender(const int &sender)
{
    m_sender = sender;
    emit senderChanged();
}

void Client::sockt_recv_data()
{
    QByteArray data_tmp;
    data_tmp = m_socket->readAll();
    if (!data_tmp.isEmpty())
    {
        QString str = QString(data_tmp);
        setReceive(str.toInt());
    }
}

void Client::socket_disconnect()
{
    QMessageBox msgBox;
    msgBox.setText("断开连接");
    msgBox.resize(40,30);
    msgBox.exec();
}

bool Client::connected() const
{
    return m_connected;
}

void Client::setConnected(bool connected)
{
    m_connected = connected;
    emit connectedChanged();
}


void Client::setReceive(const int &receive)
{
    m_receive = receive;
    emit receiveChanged();
}

void Client::connect()
{
    m_socket->abort();
    m_socket->connectToHost(m_ip, m_port);

    if (!m_socket->waitForConnected(-1))
    {

        QMessageBox msgBox;
        msgBox.setText("连接超时");
        msgBox.resize(40,30);
        msgBox.exec();
        return;
    }
    setConnected(true);
    auto s = QString("connected");
    m_socket->write(s.toUtf8());
    m_socket->flush();

    QMessageBox msgBox;
    msgBox.setText("连接成功");
    msgBox.resize(40,30);
    msgBox.exec();
}


void Client::on_pushButton_Send_clicked()
{
    if (m_sender == -1)
        return;
    QString s = QString::number(m_sender, 10);
    if (s.size() == 0)
    {
        QMessageBox msgb;
        msgb.setText("消息为空无法发送");
        msgb.resize(60,40);
        msgb.exec();
        return;
    }

    m_socket->write(s.toUtf8());
    m_socket->flush();
}

QString Client::ip() const
{
    return m_ip;
}

void Client::setIp(const QString &ip)
{
    m_ip = ip;
    emit ipChanged();
}
