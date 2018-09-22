#ifndef CLIENT_H
#define CLIENT_H

#include <QTcpSocket>
#include <QString>
#include <QObject>
#include <QMessageBox>


class Client : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString ip READ ip WRITE setIp NOTIFY ipChanged)
    Q_PROPERTY(int receive READ receive WRITE setReceive NOTIFY receiveChanged)
    Q_PROPERTY(int sender READ sender WRITE setSender NOTIFY senderChanged)
    Q_PROPERTY(bool connected READ connected WRITE setConnected NOTIFY connectedChanged)

public:
    explicit Client(QObject *parent = 0);
    ~Client();

    int receive() const;
    int sender() const;
    void setSender(const int &sender);
    QString ip() const;
    void setIp(const QString &ip);
    void setReceive(const int &receive);

    bool connected() const;
    void setConnected(bool connected);

public slots:
    void connect();
    void on_pushButton_Send_clicked() ;
    void sockt_recv_data();
    void socket_disconnect();
signals:
    void ipChanged();
    void receiveChanged();
    void senderChanged();
    void connectedChanged();

private:
    //Ui::Widget *ui;
    QTcpSocket *m_socket;
    QString m_ip;
    int m_receive;
    int m_sender;
    qint16 m_port;
    bool m_connected;

};

#endif // CLIENT_H
