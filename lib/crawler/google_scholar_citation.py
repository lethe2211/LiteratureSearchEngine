#! /usr/bin/python
# -*- coding: utf-8 -*-

import commands

from google_scholar_bibliography import *

def get_citation(cluster_id):
    '''
    Cluster_idを受け取り，その論文が引用している論文のcluster_idを返す
    '''
    art = get_bibliography(cluster_id) # 書誌情報を返す

    citations = [] # 引用論文のcluster_id
    if art["url_pdf"][0] != None:
        # ParsCitによる引用情報の取得
        cmd = os.path.dirname(os.path.abspath(sys.argv[0])) + "/../extract_citations.sh " + art["url_pdf"][0]
        xml = commands.getoutput(cmd)
        soup = BeautifulSoup(xml, "html.parser")

        if len(soup.find_all("citation")) > 0:
            for citation_soup in soup.find_all("citation"):
                # 各引用論文について，タイトルで検索した時の上位1件のcluster_idを取得
                citation_title = citation_soup.title.string if citation_soup.title else ''
                citation_cmd = os.path.dirname(sys.argv[0]) + "/scholarpy/scholar.py -c 1 -t --csv --phrase " # CSV形式で検索
                citation_cmd += '"' + citation_title + '"' 
                csv = commands.getoutput(citation_cmd)

                citation_cid = csv.split('|')[5] if len(csv.split('|')) >= 6 else None  # 6番目がcluster_id
                if citation_cid is not None:
                    citations.append(citation_cid)
    
    return citations

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(get_citation(sys.argv[1].strip()))
