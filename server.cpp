#include "server.h"

Server::Server(QObject *parent): QObject(parent)
{
    m_port = 1234;
    m_connected = false;
    m_server = new QTcpServer();
    connect(m_server,&QTcpServer::newConnection,this,&Server::server_New_Connect);
}

void Server::server_New_Connect()
{
    m_socket = m_server->nextPendingConnection();
    QObject::connect(m_socket,&QTcpSocket::readyRead,this, &Server::socket_Recv_Data);
    QObject::connect(m_socket,&QTcpSocket::disconnected,this, &Server::socket_Disconnect);
}

void Server::socket_Recv_Data()
{
    QByteArray data_tmp;
    data_tmp = m_socket->readAll();

    if(!data_tmp.isEmpty())
    {
        QString str = QString(data_tmp);
        if(str == QString("connected"))
        {
            setConnected(true);
            return;
        }
        setReceive(str.toInt());
    }
}

void Server::socket_Disconnect()
{
    QMessageBox msgBox;
    msgBox.setText("连接断开");
    msgBox.resize(40,30);
    msgBox.exec();
}

QString Server::ipShow()
{
    QString detail="";
    QList<QNetworkInterface> list=QNetworkInterface::allInterfaces();
    for(int i=0;i<list.count();i++)
    {
        QNetworkInterface interface=list.at(i);
        if(interface.name() != QString("lo"))
        {
            QList<QNetworkAddressEntry> entryList=interface.addressEntries();
            for(int j=0;j<entryList.count();j++)
            {
                QNetworkAddressEntry entry=entryList.at(j);
                detail=detail+"\t"+tr("IP 地址：")+entry.ip().toString()+"\n";
                return detail;
            }
        }
    }
    return detail;
}

bool Server::connected() const
{
    return m_connected;
}

void Server::setConnected(bool connected)
{
    m_connected = connected;
    emit connectedChanged();
}

int Server::sender() const
{
    return m_sender;
}

void Server::setSender(const int &sender)
{
    m_sender = sender;
    emit senderChanged();
}

void Server::on_pushButton_Listen_clicked()
{
    m_server->listen(QHostAddress::Any, m_port);
//    if(!m_server->listen(QHostAddress::Any, m_port))
//    {
//        QMessageBox::critical(this,"Error！",m_server->errorString(),QMessageBox::Yes | QMessageBox::No,QMessageBox::Yes );
//    }
}

void Server::on_pushButton_Send_clicked()
{
    if(m_sender == -1)
        return;
    QString s = QString::number(m_sender, 10);
    if (s.size() == 0)
    {
        QMessageBox msgb;
        msgb.setText("无法发送空消息");
        msgb.resize(60,40);
        msgb.exec();
        return;
    }

    m_socket->write(s.toUtf8());
    m_socket->flush();
}

int Server::receive() const
{
    return m_receive;
}

void Server::setReceive(const int &receive)
{
    m_receive = receive;
    emit receiveChanged();
}
