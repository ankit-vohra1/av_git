#From http://quotes.toscrape.com/, get all unique Authors
#Use while loop to process all pages till no quotes page found
#Get the top 10 tags from the page

import requests
import bs4
import time

start_time = time.time()

base_url = "http://quotes.toscrape.com"
result = requests.get(base_url) 
soup= bs4.BeautifulSoup(result.text,"lxml")
tag_item = soup.select('.tag-item')

t = []
for tags in tag_item:
    t.append(tags.getText())

#elements have new line character in beginning and at end. Stripping the same. 
tt = [x.strip('\n') for x in t ]
print('Top tags :'+ ','.join(tt) + '\n')

for p in [x for x in ','.join(tt).split(',')]:#','.join(tt):
    print(p.ljust(20,' '))
exit
base_url = "http://quotes.toscrape.com/page/{}"

all_authors = []
pg_no=1

while pg_no:
#for x in range(18,19):
    x=pg_no
    print('\nChecking pg: '+base_url.format(x))
    result = requests.get(base_url.format(x))    
    soup = bs4.BeautifulSoup(result.text,"lxml")
    
    no_quote=soup.select('.col-md-8')
    no_quote_text=no_quote[1].text
    #print(type(no_quote_text))#.strip('\n'))
    if no_quote_text.find('No quotes found') > -1:
        print("End of pages. Total scanned: " + str(x))
        break

    authors = soup.select('.author')
    #print(authors)
    for a in authors:
        #print(a.text)
        all_authors.append(a.text)
    pg_no=pg_no+1

print('No. of authors: '+str(len(all_authors)))
print('No. of unique authors: '+str(len(set(all_authors))))

print('Time taken : ' + str(round(time.time() - start_time) )+' s' )