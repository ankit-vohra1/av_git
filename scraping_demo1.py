#Check all pages of http://books.toscrape.com/ and get books with 5 star ratings
#Get a picture and store on local
import requests
import bs4
base_url = "http://books.toscrape.com/catalogue/page-{}.html"
print('Books with star rating: five')
for x in range(1,21):
    #print('\n'+base_url.format(x))

    result = requests.get(base_url.format(x))    
    soup = bs4.BeautifulSoup(result.text,"lxml")
    #print(soup.select('img')[x]['alt'])
    #print(soup.select('p')[x]['class'])
    #print(soup.select('.star-rating five'))
    #print(soup.select('.product_pod'))

    books = soup.select(".product_pod")
    #print(books[0])        #check this to understand
    #print(books[0]('a')[1]['title'])
    for b in books:
        if len(b.select('.star-rating.Five')) > 0:
            print('\t' + b('a')[1]['title'])


#result = requests.get("http://books.toscrape.com/catalogue/page-1.html")    
#soup = bs4.BeautifulSoup(result.text,"lxml")
#print(soup.select('img')[0]['alt'])
#print(soup.select('p')[0]['class'][1])


#print(soup)
#print(soup.select('h1'))
#print(soup.select('a'))
#print(soup.select('a')[10].getText())              #grab test of a p,a,h1
#print(soup.select("#footer0"))
#print(soup.select('.content_oracle')[0].text)       #grab test of a class
#for x in soup.select('a'):          #Print all a elements
#    print(x.getText())

#Get a picture and store on local
#print(soup.select('img'))        #all image objects
#print(soup.select('img')[0]['src'])    #src of particular image object 

#img_link = requests.get("")  #get an image and store in a local file
#img_link.content              #this will store image in binary
#f = open("my_file.jpg" , "wb")
#f.write(img_link.content)
#f.close