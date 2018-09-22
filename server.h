#ifndef SERVER_H
#define SERVER_H
#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QMessageBox>
#include <QNetworkInterface>
#include <QTime>
#include <QString>

class Server : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int receive READ receive WRITE setReceive NOTIFY receiveChanged)
    Q_PROPERTY(int sender READ sender WRITE setSender NOTIFY senderChanged)
    Q_PROPERTY(bool connected READ connected WRITE setConnected NOTIFY connectedChanged)
public:
    Server(QObject *parent = 0);
    int receive() const;
    void setReceive(const int &receive);

    int sender() const;
    void setSender(const int &sender);

    bool connected() const;
    void setConnected(bool connected);

public slots:
    void on_pushButton_Listen_clicked();

    void on_pushButton_Send_clicked();

    void server_New_Connect();
    void socket_Recv_Data();
    void socket_Disconnect();
    QString ipShow();
signals:
    void receiveChanged();
    void senderChanged();
    void connectedChanged();
private:
    QTcpServer *m_server;
    QTcpSocket *m_socket;
    int m_receive;
    int m_sender;
    qint16 m_port;
    bool m_connected;

};

#endif // SERVER_H
