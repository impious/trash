from pymongo import MongoClient


def connect(ip):
	try:
		client = MongoClient(ip, 27017,serverSelectionTimeoutMS=3000)
		print client.database_names()
		dbs=client.database_names()


		#dbs, colletions
		for db in dbs:

			print "."+ db

			cols= client[db].collection_names()
			for col in cols:
				col2=col.encode('UTF8')
				print ".."+col


	except Exception,e:
		print str(e)

def main():
	for x in range(68,255):
		ip="192.168.1."+str(x)
		print "trying "+ ip
		connect(ip)

if __name__ == '__main__':
	main()
