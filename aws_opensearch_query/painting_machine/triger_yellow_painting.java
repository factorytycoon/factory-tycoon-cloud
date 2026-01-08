// 1. 데이터가 없으면 종료
if (ctx.results[0].hits.total.value == 0) {
    return false;
}

// 2. 검색된 모든 데이터 순회
for (def hit : ctx.results[0].hits.hits) {
    
    // --- [데이터 파싱] ---
    def source = hit._source;
    def sensors = source.sensors;

    // 변수 초기화
    def pres = 0.0;
    def voc = 0.0;
    def temp = 0.0;

    // sensors 배열에서 도색 공정 센서 값 추출
    for (def item : sensors) {
        if (item.type == "pres") { pres = item.value; }
        if (item.type == "voc") { voc = item.value; }
        if (item.type == "temp") { temp = item.value; }
    }

    // --- [점수 계산: Painting 공정 기준] ---
    // 기본값(Green)은 1점
    int score_pres = 1;
    int score_voc = 1;
    int score_temp = 1;

    // 1. 유해 가스(voc) 점수 산정
    // Red (10점): 500 초과
    if (voc > 500) { 
        score_voc = 10; 
    }
    // Orange (6점): 150 ~ 499 
    else if (voc >= 150 && voc <= 499) { 
        score_voc = 6; 
    }
    // Yellow (3점): 50 ~ 149 
    else if (voc >= 50 && voc <= 149) { 
        score_voc = 3; 
    }

    // 2. 분사 압력(pres) 점수 산정
    // Red (10점): 1.0 미만 or 7.0 초과
    if (pres < 1.0 || pres > 7.0) { 
        score_pres = 10; 
    }
    // Orange (3점): 3.5 미만 or 4.8 초과 (Red 구간 제외)
    else if (pres < 3.5 || pres > 4.8) { 
        score_pres = 3; 
    }
    // Yellow (2점): 3.5~3.7 or 4.3~4.8
    else if ((pres >= 3.5 && pres <= 3.7) || (pres >= 4.3 && pres <= 4.8)) { 
        score_pres = 2; 
    }

    // 3. 건조 온도(temp) 점수 산정
    // Red (10점): 80 초과
    if (temp > 80) { 
        score_temp = 10; 
    }
    // Orange (3점): 38 미만 or 55 초과 (Red 구간 제외)
    else if (temp < 38 || temp > 55) { 
        score_temp = 3; 
    }
    // Yellow (2점): 38~41 or 49~55
    else if ((temp >= 38 && temp <= 41) || (temp >= 49 && temp <= 55)) { 
        score_temp = 2; 
    }

    // 총점 합산
    int total_score = score_pres + score_voc + score_temp;

    // --- [Yellow 판별] ---
    // 조건 1: 총점이 6점 이상 (Yellow 기준) 
    // 조건 2: 총점이 7점 미만 (7점부터는 Orange 등급이므로 제외) 
    if (total_score >= 6 && total_score < 7) {
        return true; 
    }
}

return false;