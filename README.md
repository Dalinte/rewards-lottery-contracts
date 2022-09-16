# Lorrery project

Требования:

```shell
nodejs ^16.15.1
```

Руководство пользователя по участию в лотерее:
```shell
1. Получить токены-тикеты на свой кошелек. Это можно сделать на сайте walleti
2. Дать approve на трату тикетов смартконтракту lottery
3. У контракта Lottery вызвать метод playTheLottery с указанием количества тикетов, которые вы хотите вложить в лотерею. Чем больше тикетов, тем больше шанс выиграть
4. Ожидать окончания лотереи. Можно вызвать read метод endTime. Он показыват timestamp окончания лотереи
5. Участвовать в лотерее можно несколько раз. Посмотреть сколько у вас тикетов можно с помошью метода userTickets
```

Руководство администратора лотереи:
```shell
1. Задеплоить контракт Ticket
2. Задеплоить контракт Lottery с указанием адреса контракта Ticket стандарта ERC20, адресом токена для награждения (например USDT) стандарта ERC20,
   и указанием timstamp окончания лотереи. Лотерея начнется автоматически и закончится в указанное вами время. 
   Timestamp окончания лотереи можно указать https://www.unixtimestamp.com/
3. Дождаться окончания лотереи и вызвать метод completeLottery для распределения выигрыша среди участников.
   Обратите внимание, что чем больше участников, тем больший gas limit необходимо указывать
4. На контракте лотереи могут остаться неизрасходованные токены выигрыша в двух случаях:
4.1
4.2 Из за округления в меньшую сторону при распределении.
   Например, если один из победителей по итогам распределения выигрыша получит 50.9 USDT, то результат округлиться до 50. Обычно это копейки, но их можно забрать с помощью метода getUnusedRewards. Тольпо после окончания лотереи и распределеления выигрыша. Ну или если 
5. После окончания лотереи можно посмотреть победителей путем перебора winners по winnersCount

  P.S При деплое можно поменять пропорцию распреденения токенов. Задается в конструкторе:
    winnerProportions.push(WinnerProportions(50, 1));
    winnerProportions.push(WinnerProportions(5, 3));
    winnerProportions.push(WinnerProportions(1, 35));

    Это означает что:
    - 1 человек - получает 50% от суммы розыгрыша
    - 3 человека - получают по 5%
    - 35 человек - получают по 1%

    Если будете менять пропорцию, не забудьте поменять и количество победителей в переменной maxWinnerCount. Сейчас она равна 39

    Важно заметить, что победители могут повторяться (но это не критично, т.к крупный победитель всего 1). Это сделано для экономии газа, ведь лотерея с работа определением победителя трудозатратная штука
```
