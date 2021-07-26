# 使用数据库
use hotel;

# 1. 创建系统管理员表
CREATE TABLE systemAdministrator
(
	# 用户ID
	userID VARCHAR(10), # VARCHAR 
	# 用户名
	userName VARCHAR(32) NOT NULL,
	# 登录密码
	userPassword VARCHAR(32) NOT NULL,
	# 主键
	PRIMARY KEY (userID)

) ENGINE = InnoDB, charset = utf8mb4;

# 2. 创建服务员表
CREATE TABLE waiter
(
	# 工号
	waiterID VARCHAR(10), #VARCHAR
	# 姓名
	waiterName VARCHAR(32) NOT NULL,
	# 出生日期
	waiterBirthday DATE NOT NULL,
	# 身份证
	waiterIDCard CHAR(18) NOT NULL UNIQUE,
	# 系统登录密码
	waiterPassword VARCHAR(32) NOT NULL,
	# 入职日期
	waiterJoinDate DATE NOT NULL,
	# 手机
	waiterPhoneNumber CHAR(11) UNIQUE,
	# 备注
	remarks VARCHAR(32),
	# 主键
	PRIMARY KEY (waiterID)

) ENGINE = InnoDB, charset = utf8mb4;

# 3. 创建会员等级表
CREATE TABLE VIPLevel
(
	# 会员等级（主码）
	level SMALLINT,  # SMALLINT  LV 1-10
	# 享受折扣
	discount decimal(10,2) UNSIGNED,
	# 等级对应消费金额
	totalAmount BIGINT, # BIGINT
	# 备注
	remarks VARCHAR(32),
	# 主键
	PRIMARY KEY (level)

) ENGINE = InnoDB, charset = utf8mb4;

# 4. 创建房间类型表(3NF)
CREATE TABLE roomTypeAndPrice
(
	# 房间类型（主码）
	roomType VARCHAR(32),
	# 价格
	price INT UNSIGNED NOT NULL,
	# 降序
	`desc` VARCHAR(100),
	url VARCHAR(40),
	# 主键
	PRIMARY KEY (roomType)

) ENGINE = InnoDB, charset = utf8mb4;

# 5. 创建顾客信息表
CREATE TABLE customers
(
	# 顾客身份证
	customerIDCard CHAR(18),
	# 性别
	customerGender CHAR(4) check (customerGender ='男' or customerGender='女'),  # 限制 男或女  
	# 姓名
	customerName VARCHAR(16) NOT NULL,  
	# 出生日期
	customerBirthday DATE, 
	# 会员等级
	customerVIPLevel SMALLINT, # 改成 SMALLINT 
	# 手机号码
	customerPhoneNumber CHAR(11), 
	# 消费金额
	totalAmount INT UNSIGNED,  
	# 备注
	remarks VARCHAR(32),  
	# 主键
	PRIMARY KEY (customerIDCard),
	# 外键
	FOREIGN KEY (customerVIPLevel) REFERENCES VIPLevel(level)

) ENGINE = InnoDB, charset = utf8mb4;

# 6. 创建房间信息表
CREATE TABLE room
(
	# 房间号（主码）
	roomNumber CHAR(6),
	# 房间类型
	roomType VARCHAR(32) NOT NULL,
	# 状态
	roomStatus CHAR(6) check (roomStatus = '空' or roomStatus = '非空'), # 空/非空 
	# 备注
	remarks VARCHAR(32),
	# 主键
	PRIMARY KEY (roomNumber),
	# 外键
	FOREIGN KEY (roomType) REFERENCES roomTypeAndPrice(roomType)

) ENGINE = InnoDB, charset = utf8mb4;

CREATE TABLE mainOrders
(
	# 订单号
	orderNumber CHAR(32) NOT NULL,
	# 客户身份证
	customerIDCard CHAR(18),
	# 入住房间号
	roomNumber CHAR(6) NOT NULL,
	# 主键
	PRIMARY KEY (orderNumber),
	# 外键
	FOREIGN KEY (orderNumber) REFERENCES orderss(orderNumber),

) ENGINE = InnoDB, charset = utf8mb4;

# 7. 创建订单信息表
# 三种订单: 已预订，已入住，已退房
CREATE TABLE orders
(
	# 订单号
	orderNumber CHAR(32) NOT NULL, 
	# 订单状态
	orderStatus CHAR(18) check (value in ('预订中','已入住','已退房')),
	# 客户身份证
	customerIDCard CHAR(18),
	# 入住房间号
	roomNumber CHAR(6) NOT NULL,
	# 入住时间
	checkInTime DATE NOT NULL,
	# 离店时间
	checkOutTime DATE NOT NULL,
	# 需付金额(由于可能续费，不能作为外键)
	totalMoney INT UNSIGNED NOT NULL,
	# 服务员工号
	waiterID VARCHAR(10) NOT NULL,
	# 备注
	remarks VARCHAR(32),
	orderTime DATE NOT NULL,
	# 主键
	PRIMARY KEY (orderNumber),
	# 外键
	FOREIGN KEY (customerIDCard) REFERENCES customers(customerIDCard),

	FOREIGN KEY (roomNumber) REFERENCES room(roomNumber),

	FOREIGN KEY (waiterID) REFERENCES waiter(waiterID)

) ENGINE = InnoDB, charset = utf8mb4;

# 8. 创建订单跟踪信息表
# 时间为NULL，表示订单还未到此状态
CREATE TABLE orderTracking
(
	# 订单号
	orderNumber CHAR(32),
	# 预定时间（订单表中一旦有预定订单加入，那么本表新增一条记录，本字段不可能为空）
	orderTime DATE NOT NULL,
	# 实际入住时间
	checkInTime DATE,
	# 实际退房时间
	checkOutTime DATE,
	# 备注
	remarks VARCHAR(32),
	# 主键
	PRIMARY KEY (orderNumber),
	# 同时作为外键
	FOREIGN KEY (orderNumber) REFERENCES orders(orderNumber)

) ENGINE = InnoDB, charset = utf8mb4;

# 9. 创建续费延长表
# 客户需要续费延长时，直接更新订单表中的日期以及金额
# 由于订单状态未变，跟踪表中无法体现此订单续费了，所以增加此续费表
CREATE TABLE timeExtension    
(
	# 操作记录号
	operatingID INT UNSIGNED AUTO_INCREMENT,
	# 操作的订单号(是记录中的订单号，外码，参照订单表)
	orderNumber CHAR(32),
	# 住房原到期日期
	oldExpiryDate DATE NOT NULL,
	# 住房新到期日期
	newExpiryDate DATE NOT NULL,
	# 需要添加的金额
	addedMoney INT UNSIGNED NOT NULL,
	# 主键
	PRIMARY KEY (operatingID),
	# 外键
	FOREIGN KEY (orderNumber) REFERENCES orders(orderNumber)

) ENGINE = InnoDB, charset = utf8mb4;



###### 视图 

# 创建收入视图
CREATE view incomeView
as
# 选择退房时间，总金额，订单数量
SELECT checkOutTime co, sum(totalMoney) tot, count(*) num FROM orders 
WHERE orders.orderNumber
in (
SELECT ordertracking.orderNumber FROM ordertracking
    WHERE ordertracking.checkOutTime is not null
)
GROUP BY co ;


# 创建客户折扣视图
CREATE view customerVipLevelInfo
as
# 选择客户以及对应的VIP等级
SELECT 
    customers.*, viplevel.discount
FROM
    customers, viplevel
WHERE
    customers.customerVIPLevel = viplevel.level ;

 
# 创建房间信息视图
CREATE VIEW roomInfo
AS
SELECT 
    room.*, rp.price, rp.`desc`,
    rp.url
FROM
    room, roomtypeandprice rp
WHERE
    room.roomType = rp.roomType ;


# 创建续费订单视图
CREATE VIEW timeExtensionOrdersView
AS
# 选择订单号，顾客名，手机号码，房间号，入住时间，旧的到期时间，新的到期时间以及增加的金额
SELECT 
    tt.orderNumber,
    ct.customerName,
    ct.customerPhoneNumber,
    od.roomNumber,
    od.checkInTime,
    tt.oldExpiryDate,
    tt.newExpiryDate,
    tt.addedMoney
FROM
    timeextension tt, orders od, customers ct
WHERE
    tt.orderNumber = od.orderNumber
AND
    od.customerIDCard = ct.customerIDCard ;


# 创建订单视图
CREATE VIEW orderviews as
SELECT
    orders.orderNumber,
    orders.orderStatus,
    customers.customerName,
    room.roomNumber,
    room.roomType,
    orders.orderTime,
    orders.checkInTime,
    orders.checkOutTime,
    customers.customerPhoneNumber,
    orders.totalMoney FROM
    orders, room, customers, roomtypeandprice
WHERE
    orders.customerIDCard = customers.customerIDCard
AND
    room.roomType = roomtypeandprice.roomType
AND 
    orders.roomNumber = room.roomNumber
ORDER BY
    orders.orderNumber DESC;

# Customers 顾客信息表 触发器
DROP TRIGGER IF EXISTS `insertCustomerLevelTrigger`;
delimiter ;;
# 创建客户折扣触发器
CREATE TRIGGER `insertCustomerLevelTrigger` BEFORE INSERT ON `customers` FOR EACH ROW begin 
# 消费金额<200 VIP等级为1
				if new.totalAmount<200
					then 
					set new.customerVIPLevel =1 ;
# 200<消费金额<500 VIP等级为2					
				elseif  new.totalAmount<500
					then 
					set new.customerVIPLevel =2 ;
# 500<消费金额<1000 VIP等级为3					
				elseif new.totalAmount<1000
					then 
					set new.customerVIPLevel =3 ;
# 1000<消费金额<2000 VIP等级为4
				elseif new.totalAmount<2000
					then 
					set new.customerVIPLevel =4 ;
# 2000<消费金额<3000 VIP等级为5				
				elseif new.totalAmount<3000
					then 
					set new.customerVIPLevel =5 ;
# 3000<消费金额<5000 VIP等级为6					
				elseif new.totalAmount<5000
					then 
					set new.customerVIPLevel =6 ;
					end if;
			end
;;
delimiter ;

# Customers 顾客信息表 触发器
DROP TRIGGER IF EXISTS `updateCustomerLevelTrigger`;
delimiter ;;
# 创建客户消费金额更新后的触发器
CREATE TRIGGER `updateCustomerLevelTrigger` BEFORE UPDATE ON `customers` FOR EACH ROW begin 
				if new.totalAmount<200
					then 
					set new.customerVIPLevel =1 ;
					
				elseif  new.totalAmount<500
					then 
					set new.customerVIPLevel =2 ;
					
				elseif new.totalAmount<1000
					then 
					set new.customerVIPLevel =3 ;
				elseif new.totalAmount<2000
					then 
					set new.customerVIPLevel =4 ;
				elseif new.totalAmount<3000
					then 
					set new.customerVIPLevel =5 ;
				elseif new.totalAmount<5000
					then 
					set new.customerVIPLevel =6 ;
					end if;
			end
;;
delimiter ;

# Orders 订单信息表 触发器
DROP TRIGGER IF EXISTS `insertAddMoneyToOrdersTrigger`;
delimiter ;;
# 创建更新的顾客消费总金额的触发器
CREATE TRIGGER `insertAddMoneyToOrdersTrigger` BEFORE INSERT ON `orders` FOR EACH ROW begin 
	UPDATE customers set totalAmount=totalAmount+new.totalMoney WHERE customerIDCard=new.customerIDCard ;
end
;;
delimiter ;

# Orders 订单信息表 触发器
# 创建插入订单后对订单信息进行更新的触发器
DROP TRIGGER IF EXISTS `insertOrderStatusToTrackingTrigger`;
delimiter ;;
CREATE TRIGGER `insertOrderStatusToTrackingTrigger` AFTER INSERT ON `orders` FOR EACH ROW begin 
				if new.orderStatus='预定中'
					then
					INSERT INTO ordertracking VALUES ( new.orderNumber, new.orderTime, NULL, NULL, NULL);
				elseif new.orderStatus='已入住'
					then
					INSERT INTO ordertracking VALUES ( new.orderNumber, new.orderTime, NULL, NULL, NULL);
					update orderTracking set checkInTime=new.checkInTime,orderTime=new.checkInTime WHERE orderNumber=new.orderNumber ;
				elseif new.orderStatus='已退房' 
					then
					INSERT INTO ordertracking VALUES ( new.orderNumber, new.orderTime, NULL, NULL, NULL);
					update orderTracking set checkInTime=new.checkInTime,orderTime=new.checkInTime,checkOutTime=new.checkOutTime WHERE orderNumber=new.orderNumber ;
				end if ;
			end
;;
delimiter ;

# Orders 订单信息表 触发器
DROP TRIGGER IF EXISTS `insertRoomStatusByOrdersTrigger`;
delimiter ;;
# 创建插入订单后对房间状态进行更新的触发器
CREATE TRIGGER `insertRoomStatusByOrdersTrigger` AFTER INSERT ON `orders` FOR EACH ROW begin 
				if new.orderStatus='已入住'
					then
					update room  set roomStatus='非空' WHERE roomNumber=new.roomNumber ;
				elseif new.orderStatus='已退房'
					then 
					update room  set roomStatus='空' WHERE roomNumber=new.roomNumber ;
				end if ;
			end
;;
delimiter ;

# Orders 订单信息表 触发器
DROP TRIGGER IF EXISTS `updateOrderStatustoTrackingTrigger`;
delimiter ;;
# 创建对订单完整性进行控制的触发器
CREATE TRIGGER `updateOrderStatustoTrackingTrigger` BEFORE UPDATE ON `orders` FOR EACH ROW begin 
				
				if new.orderStatus='已入住'
					then
					update orderTracking set checkInTime=new.checkInTime  WHERE orderNumber=new.orderNumber ;
				elseif new.orderStatus='已退房'
					then 
					update orderTracking set checkOutTime=new.checkOutTime WHERE orderNumber=new.orderNumber ;
				end if ;
			end
;;
delimiter ;

# Orders 订单信息表 触发器
# 创建对房间完整性进行控制的触发器
DROP TRIGGER IF EXISTS `updateRoomStatusByOrdersTrigger`;
delimiter ;;
CREATE TRIGGER `updateRoomStatusByOrdersTrigger` BEFORE UPDATE ON `orders` FOR EACH ROW begin 
				if new.orderStatus='已入住'
					then
					update room  set roomStatus='非空' WHERE roomNumber=new.roomNumber ;
				elseif new.orderStatus='已退房'
					then 
					update room  set roomStatus='空' WHERE roomNumber=new.roomNumber ;
				end if ;
			end
;;
delimiter ;

# 创建对续费订单总金额进行更新的触发器
DROP TRIGGER IF EXISTS `insertMoneyToTimeExtensionTrigger`;
delimiter ;;
CREATE TRIGGER `insertMoneyToTimeExtensionTrigger` BEFORE INSERT ON `timeextension` FOR EACH ROW begin 
				
				UPDATE orders set totalMoney=totalMoney+new.addedMoney WHERE  orderNumber=new.orderNumber ;
				UPDATE customers set totalAmount=totalAmount+new.addedMoney  WHERE customerIDCard = (SELECT customerIDCard FROM orders WHERE new.orderNumber=orderNumber) ;
			end
;;
delimiter ;


# 建立的索引 

# 创建room 中roomtype和roomstatus 的混合索引
CREATE index indexRoomTypeStatus on room (roomType, roomStatus);
# 创建系统管理员id和password的混合索引
CREATE index indexSystemAdminIDPassword on systemadministrator (userID, userPassword);
# 创建宾馆管理员id和password的混合索引
CREATE index indexWaiterIDPassword on waiter (waiterID, waiterPassword);
# 创建customers中姓名的索引
CREATE index indexCustomerName on customers (customerName);
# 创建customers中手机号的索引
CREATE index indexCustomerPhoneNumber on customers (customerPhoneNumber);
# 创建customers中VIP等级的索引
CREATE index indexCustomerVIPLevel on customers (customerVIPLevel);
# 创建orders中orderNumber和orderStatus 的混合索引 
CREATE index indexOrderStatusNumber on orders (orderNumber, orderStatus);
# 创建roomtypeandprice中roomType和price的混合索引
CREATE index indexRoomTypePrice on roomtypeandprice (roomType, price);



# 插入服务员
INSERT INTO `waiter` VALUES ('74893', 'fdsfd', '2000-01-01', '430826200001012234', '1234', '2018-01-01', '13256463546', 'ewe');
INSERT INTO `waiter` VALUES ('rob', 'yf1', '1998-10-22', '430723199810226011', '3342', '2017-12-06', '13225632637', NULL);
INSERT INTO `waiter` VALUES ('yzc', 'Yangzi', '2017-12-28', '340122199707014848', 'root', '2018-01-04', '13215636922', boss);
INSERT INTO `waiter` VALUES ('gxy', 'Taoxin', '2017-12-21', '342623199807263812', 'root', '2017-12-05', '18856336515', boss_wife);
INSERT INTO `waiter` VALUES ('lx1', 'lx1', '2018-01-03', '123123124124124123', '1234', '2018-01-17', '13287879898', '1232null');
INSERT INTO `waiter` VALUES ('mm', 'nn', '1992-01-01', '430899199201011234', '1234', '2018-01-01', '13225632736', 'qwe');


# 插入VIP等级以及对应的折扣和消费金额
INSERT INTO `viplevel` VALUES (1, 0.99, 200, NULL);
INSERT INTO `viplevel` VALUES (2, 0.98, 500, NULL);
INSERT INTO `viplevel` VALUES (3, 0.97, 1000, NULL);
INSERT INTO `viplevel` VALUES (4, 0.96, 2000, NULL);
INSERT INTO `viplevel` VALUES (5, 0.95, 3000, NULL);
INSERT INTO `viplevel` VALUES (6, 0.94, 5000, NULL);


# 插入系统管理员
INSERT INTO `systemadministrator` VALUES ('rob', 'yf', '3342');
INSERT INTO `systemadministrator` VALUES ('yzc', 'Yangzi', 'root');
INSERT INTO `systemadministrator` VALUES ('gxy', 'Taoxin', 'root');


#插入房间详细信息
INSERT INTO `roomtypeandprice` VALUES ('标准间(单人)', 178, '房间: 18㎡ | 小床: 1.2m | 楼层: 1-4层 | 包含WIFI', '/images/1.jpg');
INSERT INTO `roomtypeandprice` VALUES ('标准间(双人)', 308, '房间: 20-25㎡ | 双床: 1.2m | 楼层: 2-4层 | 包含WIFI', '/images/2.jpg');
INSERT INTO `roomtypeandprice` VALUES ('大床房(单人/双人)', 288, '房间: 12㎡ | 大床: 1.5m | 楼层: 1-4层 | 包含WIFI', '/images/3.jpg');
INSERT INTO `roomtypeandprice` VALUES ('商务间(单人/双人)', 398, '房间: 18-20㎡ | 大床: 1.8m | 楼层: 2-4层 | 包含WIFI', '/images/4.jpg');
INSERT INTO `roomtypeandprice` VALUES ('豪华套房(单人/双人)', 598, '房间: 40-50㎡ | 双大床: 1.5m | 楼层: 5层 | 包含WIFI', '/images/5.jpg');


#插入房间编号类型和状态信息
INSERT INTO `room` VALUES ('000001', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000002', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000003', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000004', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000005', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000006', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000007', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000008', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000009', '标准间(单人)', '非空', NULL);
INSERT INTO `room` VALUES ('000010', '标准间(双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000011', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000012', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000013', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000014', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000015', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000016', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000017', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000018', '标准间(双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000019', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000020', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000021', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000022', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000023', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000024', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000025', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000026', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000027', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000028', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000029', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000030', '标准间(双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000031', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000032', '大床房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000033', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000034', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000035', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000036', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000037', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000038', '标准间(双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000039', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000040', '豪华套房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000041', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000042', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000043', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000044', '标准间(双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000045', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000046', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000047', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000048', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000049', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000050', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000051', '豪华套房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000052', '豪华套房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000053', '大床房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000054', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000055', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000056', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000057', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000058', '商务间(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000059', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000060', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000061', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000062', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000063', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000064', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000065', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000066', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000067', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000068', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000069', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000070', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000071', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000072', '商务间(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000073', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000074', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000075', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000076', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000077', '大床房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000078', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000079', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000080', '标准间(双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000081', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000082', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000083', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000084', '大床房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000085', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000086', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('000087', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000088', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000089', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000090', '豪华套房(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000091', '标准间(双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000092', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000093', '商务间(单人/双人)', '非空', NULL);
INSERT INTO `room` VALUES ('000094', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000095', '标准间(双人)', '空', NULL);
INSERT INTO `room` VALUES ('000096', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000097', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000098', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000099', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000100', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000101', '大床房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('000102', '标准间(单人)', '空', NULL);
INSERT INTO `room` VALUES ('001188', '豪华套房(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('012341', '商务间(单人/双人)', '空', NULL);
INSERT INTO `room` VALUES ('100000', '商务间(单人/双人)', '空', '');
INSERT INTO `room` VALUES ('123422', '商务间(单人/双人)', '空', '');



