package com.ssp.menuservice;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class MenuControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void returnsMenuForKnownUnit() throws Exception {
        mockMvc.perform(get("/menu/LHR-T5-001"))
                .andExpect(status().isOk());
    }

    @Test
    void returns404ForUnknownUnit() throws Exception {
        mockMvc.perform(get("/menu/DOES-NOT-EXIST"))
                .andExpect(status().isNotFound());
    }

    @Test
    void healthEndpointReturns200() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk());
    }
}
